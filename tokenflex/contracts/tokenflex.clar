;; TokenFlex: Dynamic Subscription Tokenization Platform
;; A contract for managing membership access through tokenized subscriptions

;; Define NFT trait
(define-trait digital-asset-trait
    (
        ;; Last token ID
        (get-latest-asset-id () (response uint uint))
        ;; URI for token metadata
        (get-asset-metadata (uint) (response (optional (string-ascii 256)) uint))
        ;; Owner of a token
        (get-holder (uint) (response (optional principal) uint))
        ;; Transfer token
        (move-asset (uint principal principal) (response bool uint))
    )
)

;; Constants
(define-constant ADMIN_WALLET tx-sender)
(define-constant ERR_PERMISSION_DENIED (err u100))
(define-constant ERR_DUPLICATE_ENTRY (err u101))
(define-constant ERR_INVALID_MEMBERSHIP (err u102))
(define-constant ERR_MEMBERSHIP_LAPSED (err u103))
(define-constant ERR_TOKEN_MISSING (err u104))
(define-constant ERR_RESOURCE_MISSING (err u105))

;; Data Variables
(define-data-var platform-status bool true)
(define-data-var latest-asset-id uint u0)

;; Define membership plans
(define-map membership-plans
    uint  ;; plan-id
    {
        title: (string-ascii 24),
        period: uint,         ;; period in blocks
        fee: uint            ;; fee in STX
    }
)

;; Track active memberships and associated tokens
(define-map member-registry
    principal  ;; member address
    {
        plan-id: uint,
        valid-until: uint,      ;; block height when membership expires
        status: bool,
        asset-id: uint        ;; associated NFT token ID
    }
)

;; Token ownership tracking
(define-map asset-registry 
    uint  ;; asset-id 
    principal
)

;; Resource permission mapping
(define-map resource-permissions
    {resource-id: uint, plan-id: uint}
    bool
)

;; Resource details
(define-map resource-registry
    uint  ;; resource-id
    {
        title: (string-ascii 64),
        provider: principal,
        min-plan: uint
    }
)

;; NFT Implementation

(define-public (move-asset (asset-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) ERR_PERMISSION_DENIED)
        (asserts! (is-holder? sender asset-id) ERR_PERMISSION_DENIED)
        (map-set asset-registry asset-id recipient)
        (ok true)
    )
)

(define-public (get-asset-metadata (asset-id uint))
    (ok none)
)

(define-read-only (get-holder (asset-id uint))
    (ok (map-get? asset-registry asset-id))
)

(define-read-only (get-latest-asset-id)
    (ok (var-get latest-asset-id))
)

;; Read-only functions

(define-read-only (get-membership-plan (plan-id uint))
    (map-get? membership-plans plan-id)
)

(define-read-only (get-member-details (member principal))
    (map-get? member-registry member)
)

(define-read-only (is-membership-valid (member principal))
    (match (map-get? member-registry member)
        membership (and 
            (get status membership)
            (< block-height (get valid-until membership))
        )
        false
    )
)

(define-read-only (can-access-resource (user principal) (resource-id uint))
    (let (
        (membership (unwrap! (map-get? member-registry user) false))
        (resource (unwrap! (map-get? resource-registry resource-id) false))
    )
    (and
        (is-membership-valid user)
        (>= (get plan-id membership) (get min-plan resource))
        (is-holder? user (get asset-id membership))
    ))
)

(define-private (is-holder? (user principal) (asset-id uint))
    (match (map-get? asset-registry asset-id)
        holder (is-eq holder user)
        false
    )
)

;; Public functions

;; Create a new membership plan (admin only)
(define-public (create-membership-plan (plan-id uint) (title (string-ascii 24)) (period uint) (fee uint))
    (begin
        (asserts! (is-admin tx-sender) ERR_PERMISSION_DENIED)
        (asserts! (is-none (map-get? membership-plans plan-id)) ERR_DUPLICATE_ENTRY)
        (ok (map-set membership-plans plan-id {
            title: title,
            period: period,
            fee: fee
        }))
    )
)

;; Mint NFT for new membership
(define-private (mint-membership-token (recipient principal))
    (let (
        (asset-id (+ (var-get latest-asset-id) u1))
    )
    (begin
        (var-set latest-asset-id asset-id)
        (map-set asset-registry asset-id recipient)
        asset-id
    ))
)

;; Subscribe to a plan
(define-public (join-plan (plan-id uint))
    (let (
        (plan (unwrap! (map-get? membership-plans plan-id) ERR_INVALID_MEMBERSHIP))
        (current-membership (map-get? member-registry tx-sender))
        (new-asset-id (mint-membership-token tx-sender))
    )
    (begin
        (asserts! (is-platform-active) ERR_PERMISSION_DENIED)
        ;; Transfer payment
        (try! (stx-transfer? (get fee plan) tx-sender ADMIN_WALLET))
        
        ;; Calculate expiration
        (let ((new-expiration (+ block-height (get period plan))))
            (ok (map-set member-registry tx-sender {
                plan-id: plan-id,
                valid-until: new-expiration,
                status: true,
                asset-id: new-asset-id
            }))
        )
    ))
)

;; Cancel membership
(define-public (terminate-membership)
    (let (
        (membership (unwrap! (map-get? member-registry tx-sender) ERR_INVALID_MEMBERSHIP))
    )
    (begin
        (map-delete asset-registry (get asset-id membership))
        (ok (map-set member-registry tx-sender {
            plan-id: u0,
            valid-until: u0,
            status: false,
            asset-id: u0
        }))
    ))
)

;; Resource Management

(define-public (register-resource (resource-id uint) (title (string-ascii 64)) (min-plan uint))
    (begin
        (asserts! (is-admin tx-sender) ERR_PERMISSION_DENIED)
        (ok (map-set resource-registry resource-id {
            title: title,
            provider: tx-sender,
            min-plan: min-plan
        }))
    )
)

(define-public (configure-resource-access (resource-id uint) (plan-id uint) (access-granted bool))
    (begin
        (asserts! (is-admin tx-sender) ERR_PERMISSION_DENIED)
        (ok (map-set resource-permissions {resource-id: resource-id, plan-id: plan-id} access-granted))
    )
)

;; Administrative functions

(define-private (is-admin (caller principal))
    (is-eq caller ADMIN_WALLET)
)

(define-public (set-platform-status (active bool))
    (begin
        (asserts! (is-admin tx-sender) ERR_PERMISSION_DENIED)
        (ok (var-set platform-status active))
    )
)

(define-private (is-platform-active)
    (var-get platform-status)
)

;; Initialize contract
(begin
    ;; Initialize Basic Plan
    (try! (create-membership-plan u1 "Basic" u144 u100000000))  ;; 100 STX, 1 day
    ;; Initialize Premium Plan
    (try! (create-membership-plan u2 "Premium" u4320 u250000000)) ;; 250 STX, 30 days
    ;; Initialize Elite Plan
    (try! (create-membership-plan u3 "Elite" u52560 u1000000000)) ;; 1000 STX, 365 days
    
    (print "TokenFlex platform initialized")
)
