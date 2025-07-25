;; Gaming NFT Marketplace - A comprehensive platform for in-game asset ownership, trading, and player progression
;; Enables players to mint, trade, and manage digital gaming assets with built-in marketplace functionality
;; Supports player statistics tracking and batch operations for efficient game integration

;; ERROR CONSTANTS
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-ASSET-NOT-FOUND (err u101))
(define-constant ERR-FORBIDDEN-ACTION (err u102))
(define-constant ERR-INVALID-PARAMETERS (err u103))
(define-constant ERR-INVALID-PRICE-AMOUNT (err u104))
(define-constant ERR-MARKETPLACE-LISTING-NOT-FOUND (err u105))

;; CONFIGURATION CONSTANTS
(define-constant contract-deployer tx-sender)
(define-constant maximum-player-level u100)
(define-constant maximum-experience-points u10000)
(define-constant maximum-metadata-uri-length u256)
(define-constant maximum-batch-operation-size u10)

;; DATA STORAGE MAPS

;; Core gaming asset registry
(define-map gaming-asset-registry 
    { asset-identifier: uint }
    { 
        current-owner: principal, 
        metadata-location: (string-utf8 256), 
        is-transferable: bool 
    })

;; Player progression and statistics
(define-map player-progression-data
    { player-address: principal }
    { 
        total-experience: uint, 
        current-level: uint 
    })

;; Active marketplace listings
(define-map active-marketplace-listings
    { asset-identifier: uint }
    { 
        listing-owner: principal, 
        asking-price: uint, 
        listing-block-height: uint 
    })

;; STATE VARIABLES
(define-data-var next-asset-identifier uint u0)

;; VALIDATION HELPER FUNCTIONS

;; Validates that an asset exists and returns its data
(define-private (validate-and-get-asset-data (asset-identifier uint))
    (let ((asset-data (map-get? gaming-asset-registry { asset-identifier: asset-identifier })))
        (asserts! (and 
                (is-some asset-data)
                (<= asset-identifier (var-get next-asset-identifier)))
            ERR-ASSET-NOT-FOUND)
        (ok (unwrap-panic asset-data))))

;; Validates metadata URI meets requirements
(define-private (is-valid-metadata-uri (metadata-uri (string-utf8 256)))
    (let ((uri-character-count (len metadata-uri)))
        (and 
            (> uri-character-count u0)
            (<= uri-character-count maximum-metadata-uri-length))))

;; Validates batch operation parameters
(define-private (validate-batch-operation-parameters (first-list-length uint) (second-list-length uint))
    (and 
        (> first-list-length u0)
        (<= first-list-length maximum-batch-operation-size)
        (is-eq first-list-length second-list-length)))

;; ASSET CREATION FUNCTIONS

;; Creates multiple gaming assets in a single transaction
(define-public (create-multiple-gaming-assets 
    (metadata-uri-list (list 10 (string-utf8 256))) 
    (transferability-settings (list 10 bool)))
    (begin
        (asserts! (is-eq tx-sender contract-deployer) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-batch-operation-parameters 
            (len metadata-uri-list) 
            (len transferability-settings)) 
            ERR-INVALID-PARAMETERS)
        (let ((created-asset-results 
            (map create-individual-gaming-asset 
                metadata-uri-list 
                transferability-settings)))
            (ok created-asset-results))))

;; Helper function for individual asset creation during batch operations
(define-private (create-individual-gaming-asset 
    (metadata-uri (string-utf8 256))
    (is-transferable bool))
    (let ((new-asset-identifier (+ (var-get next-asset-identifier) u1)))
        (asserts! (is-valid-metadata-uri metadata-uri) ERR-INVALID-PARAMETERS)
        (map-set gaming-asset-registry
            { asset-identifier: new-asset-identifier }
            { 
                current-owner: contract-deployer,
                metadata-location: metadata-uri,
                is-transferable: is-transferable 
            })
        (var-set next-asset-identifier new-asset-identifier)
        (ok new-asset-identifier)))

;; Creates a single gaming asset
(define-public (create-single-gaming-asset (metadata-uri (string-utf8 256)) (is-transferable bool))
    (let ((new-asset-identifier (+ (var-get next-asset-identifier) u1)))
        (asserts! (is-eq tx-sender contract-deployer) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (is-valid-metadata-uri metadata-uri) ERR-INVALID-PARAMETERS)
        (map-set gaming-asset-registry
            { asset-identifier: new-asset-identifier }
            { 
                current-owner: tx-sender,
                metadata-location: metadata-uri,
                is-transferable: is-transferable 
            })
        (var-set next-asset-identifier new-asset-identifier)
        (ok new-asset-identifier)))

;; ASSET TRANSFER FUNCTIONS

;; Transfers multiple assets to different recipients
(define-public (transfer-multiple-gaming-assets 
    (asset-identifier-list (list 10 uint)) 
    (recipient-address-list (list 10 principal)))
    (begin
        (asserts! (validate-batch-operation-parameters 
            (len asset-identifier-list) 
            (len recipient-address-list)) 
            ERR-INVALID-PARAMETERS)
        (let ((transfer-operation-results 
            (map execute-individual-asset-transfer 
                asset-identifier-list 
                recipient-address-list)))
            (ok transfer-operation-results))))

;; Helper function for individual asset transfers during batch operations
(define-private (execute-individual-asset-transfer 
    (asset-identifier uint)
    (recipient-address principal))
    (let ((current-asset-data (unwrap-panic (validate-and-get-asset-data asset-identifier))))
        (asserts! (and
                (is-eq (get current-owner current-asset-data) tx-sender)
                (get is-transferable current-asset-data)
                (not (is-eq recipient-address tx-sender)))
            ERR-FORBIDDEN-ACTION)
        (map-set gaming-asset-registry
            { asset-identifier: asset-identifier }
            { 
                current-owner: recipient-address,
                metadata-location: (get metadata-location current-asset-data),
                is-transferable: (get is-transferable current-asset-data) 
            })
        (ok true)))

;; Transfers ownership of a single gaming asset
(define-public (transfer-single-gaming-asset (asset-identifier uint) (recipient-address principal))
    (begin
        (asserts! (<= asset-identifier (var-get next-asset-identifier)) ERR-INVALID-PARAMETERS)
        (let ((current-asset-data (try! (validate-and-get-asset-data asset-identifier))))
            (asserts! (and
                    (is-eq (get current-owner current-asset-data) tx-sender)
                    (get is-transferable current-asset-data)
                    (not (is-eq recipient-address tx-sender)))
                ERR-FORBIDDEN-ACTION)
            (map-set gaming-asset-registry
                { asset-identifier: asset-identifier }
                { 
                    current-owner: recipient-address,
                    metadata-location: (get metadata-location current-asset-data),
                    is-transferable: (get is-transferable current-asset-data) 
                })
            (ok true))))

;; MARKETPLACE FUNCTIONS

;; Creates a marketplace listing for an asset
(define-public (create-marketplace-listing (asset-identifier uint) (asking-price uint))
    (begin
        (asserts! (<= asset-identifier (var-get next-asset-identifier)) ERR-INVALID-PARAMETERS)
        (let ((current-asset-data (try! (validate-and-get-asset-data asset-identifier))))
            (asserts! (and 
                    (is-eq (get current-owner current-asset-data) tx-sender)
                    (> asking-price u0)
                    (get is-transferable current-asset-data))
                ERR-INVALID-PRICE-AMOUNT)
            (map-set active-marketplace-listings
                { asset-identifier: asset-identifier }
                { 
                    listing-owner: tx-sender, 
                    asking-price: asking-price, 
                    listing-block-height: block-height 
                })
            (ok true))))

;; Executes the purchase of a listed asset
(define-public (execute-asset-purchase (asset-identifier uint))
    (begin
        (asserts! (<= asset-identifier (var-get next-asset-identifier)) ERR-INVALID-PARAMETERS)
        (let
            ((current-asset-data (try! (validate-and-get-asset-data asset-identifier)))
             (marketplace-listing-data (unwrap! (map-get? active-marketplace-listings { asset-identifier: asset-identifier }) ERR-MARKETPLACE-LISTING-NOT-FOUND)))
            (asserts! (and
                    (not (is-eq (get listing-owner marketplace-listing-data) tx-sender))
                    (get is-transferable current-asset-data))
                ERR-FORBIDDEN-ACTION)
            (try! (stx-transfer? (get asking-price marketplace-listing-data) tx-sender (get listing-owner marketplace-listing-data)))
            (map-set gaming-asset-registry
                { asset-identifier: asset-identifier }
                { 
                    current-owner: tx-sender,
                    metadata-location: (get metadata-location current-asset-data),
                    is-transferable: (get is-transferable current-asset-data) 
                })
            (map-delete active-marketplace-listings { asset-identifier: asset-identifier })
            (ok true))))

;; Removes an asset from marketplace listings
(define-public (remove-marketplace-listing (asset-identifier uint))
    (begin
        (asserts! (<= asset-identifier (var-get next-asset-identifier)) ERR-INVALID-PARAMETERS)
        (let ((marketplace-listing-data (unwrap! (map-get? active-marketplace-listings { asset-identifier: asset-identifier }) ERR-MARKETPLACE-LISTING-NOT-FOUND)))
            (asserts! (is-eq tx-sender (get listing-owner marketplace-listing-data)) ERR-FORBIDDEN-ACTION)
            (map-delete active-marketplace-listings { asset-identifier: asset-identifier })
            (ok true))))

;; ===== PLAYER PROGRESSION FUNCTIONS =====

;; Updates player statistics and progression data
(define-public (update-player-progression-statistics (experience-points uint) (player-level uint))
    (begin
        (asserts! (<= experience-points maximum-experience-points) ERR-INVALID-PARAMETERS)
        (asserts! (<= player-level maximum-player-level) ERR-INVALID-PARAMETERS)
        (map-set player-progression-data
            { player-address: tx-sender }
            { 
                total-experience: experience-points, 
                current-level: player-level 
            })
        (ok true)))

;; READ-ONLY QUERY FUNCTIONS

;; Retrieves detailed information about a gaming asset
(define-read-only (get-gaming-asset-information (asset-identifier uint))
    (if (<= asset-identifier (var-get next-asset-identifier))
        (map-get? gaming-asset-registry { asset-identifier: asset-identifier })
        none))

;; Retrieves marketplace listing information for an asset
(define-read-only (get-marketplace-listing-information (asset-identifier uint))
    (map-get? active-marketplace-listings { asset-identifier: asset-identifier }))

;; Retrieves player progression and statistics data
(define-read-only (get-player-progression-information (player-address principal))
    (map-get? player-progression-data { player-address: player-address }))

;; Returns the total number of gaming assets created
(define-read-only (get-total-gaming-assets-count)
    (var-get next-asset-identifier))