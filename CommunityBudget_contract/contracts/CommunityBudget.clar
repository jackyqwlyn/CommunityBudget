
;; title: CommunityBudget
;; version: 1.0.0
;; summary: A participatory democracy platform for local spending priorities and project funding
;; description: This contract enables communities to propose, vote on, and fund local projects through democratic processes

;; traits
;;

;; token definitions
;;

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-voted (err u102))
(define-constant err-proposal-ended (err u103))
(define-constant err-proposal-not-ended (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-invalid-amount (err u106))
(define-constant err-proposal-not-approved (err u107))
(define-constant err-already-funded (err u108))

;; data vars
(define-data-var proposal-id-nonce uint u0)
(define-data-var total-community-budget uint u0)
(define-data-var allocated-budget uint u0)

;; data maps
;; Proposal structure: {id, title, description, amount, proposer, votes-for, votes-against, end-block, status, funded}
(define-map proposals
    { proposal-id: uint }
    {
        title: (string-ascii 100),
        description: (string-ascii 500),
        amount: uint,
        proposer: principal,
        votes-for: uint,
        votes-against: uint,
        end-block: uint,
        status: (string-ascii 20), ;; "active", "approved", "rejected", "funded"
        funded: bool
    }
)

;; Track individual votes to prevent double voting
(define-map votes
    { proposal-id: uint, voter: principal }
    { vote: bool } ;; true = for, false = against
)

;; Track community members eligible to vote
(define-map community-members
    { member: principal }
    { active: bool }
)

;; public functions

;; Initialize the contract with a community budget
(define-public (initialize-budget (budget uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set total-community-budget budget)
        (ok true)
    )
)

;; Add a community member
(define-public (add-community-member (member principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set community-members { member: member } { active: true })
        (ok true)
    )
)

;; Remove a community member
(define-public (remove-community-member (member principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set community-members { member: member } { active: false })
        (ok true)
    )
)

;; Submit a new proposal
(define-public (submit-proposal (title (string-ascii 100)) (description (string-ascii 500)) (amount uint) (voting-period uint))
    (let
        (
            (proposal-id (+ (var-get proposal-id-nonce) u1))
            (end-block (+ block-height voting-period))
        )
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (<= amount (- (var-get total-community-budget) (var-get allocated-budget))) err-insufficient-funds)
        (asserts! (is-community-member tx-sender) err-owner-only)

        (map-set proposals
            { proposal-id: proposal-id }
            {
                title: title,
                description: description,
                amount: amount,
                proposer: tx-sender,
                votes-for: u0,
                votes-against: u0,
                end-block: end-block,
                status: "active",
                funded: false
            }
        )
        (var-set proposal-id-nonce proposal-id)
        (ok proposal-id)
    )
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
    (let
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
            (current-votes-for (get votes-for proposal))
            (current-votes-against (get votes-against proposal))
        )
        (asserts! (is-community-member tx-sender) err-owner-only)
        (asserts! (is-none (map-get? votes { proposal-id: proposal-id, voter: tx-sender })) err-already-voted)
        (asserts! (< block-height (get end-block proposal)) err-proposal-ended)
        (asserts! (is-eq (get status proposal) "active") err-proposal-ended)

        ;; Record the vote
        (map-set votes { proposal-id: proposal-id, voter: tx-sender } { vote: vote-for })

        ;; Update vote counts
        (if vote-for
            (map-set proposals
                { proposal-id: proposal-id }
                (merge proposal { votes-for: (+ current-votes-for u1) })
            )
            (map-set proposals
                { proposal-id: proposal-id }
                (merge proposal { votes-against: (+ current-votes-against u1) })
            )
        )
        (ok true)
    )
)

;; Finalize a proposal (after voting period ends)
(define-public (finalize-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
            (votes-for (get votes-for proposal))
            (votes-against (get votes-against proposal))
        )
        (asserts! (>= block-height (get end-block proposal)) err-proposal-not-ended)
        (asserts! (is-eq (get status proposal) "active") err-proposal-ended)

        ;; Determine if proposal is approved (simple majority)
        (if (> votes-for votes-against)
            (begin
                (map-set proposals
                    { proposal-id: proposal-id }
                    (merge proposal { status: "approved" })
                )
                (ok "approved")
            )
            (begin
                (map-set proposals
                    { proposal-id: proposal-id }
                    (merge proposal { status: "rejected" })
                )
                (ok "rejected")
            )
        )
    )
)

;; Fund an approved proposal
(define-public (fund-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) err-not-found))
            (amount (get amount proposal))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq (get status proposal) "approved") err-proposal-not-approved)
        (asserts! (is-eq (get funded proposal) false) err-already-funded)
        (asserts! (<= amount (- (var-get total-community-budget) (var-get allocated-budget))) err-insufficient-funds)

        ;; Update proposal status and allocated budget
        (map-set proposals
            { proposal-id: proposal-id }
            (merge proposal { status: "funded", funded: true })
        )
        (var-set allocated-budget (+ (var-get allocated-budget) amount))

        ;; In a real implementation, this would transfer funds to the proposer
        ;; For now, we just mark it as funded
        (ok true)
    )
)

;; Add funds to the community budget
(define-public (add-budget (additional-funds uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> additional-funds u0) err-invalid-amount)
        (var-set total-community-budget (+ (var-get total-community-budget) additional-funds))
        (ok true)
    )
)

;; read only functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals { proposal-id: proposal-id })
)

;; Get current proposal ID counter
(define-read-only (get-current-proposal-id)
    (var-get proposal-id-nonce)
)

;; Get total community budget
(define-read-only (get-total-budget)
    (var-get total-community-budget)
)

;; Get allocated budget
(define-read-only (get-allocated-budget)
    (var-get allocated-budget)
)

;; Get available budget
(define-read-only (get-available-budget)
    (- (var-get total-community-budget) (var-get allocated-budget))
)

;; Check if a user has voted on a proposal
(define-read-only (has-voted (proposal-id uint) (voter principal))
    (is-some (map-get? votes { proposal-id: proposal-id, voter: voter }))
)

;; Get user's vote on a proposal
(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes { proposal-id: proposal-id, voter: voter })
)

;; Check if user is a community member
(define-read-only (is-community-member (member principal))
    (default-to false (get active (map-get? community-members { member: member })))
)

;; Get proposal status
(define-read-only (get-proposal-status (proposal-id uint))
    (match (map-get? proposals { proposal-id: proposal-id })
        proposal (get status proposal)
        "not-found"
    )
)

;; Check if proposal voting has ended
(define-read-only (is-voting-ended (proposal-id uint))
    (match (map-get? proposals { proposal-id: proposal-id })
        proposal (>= block-height (get end-block proposal))
        true
    )
)

;; private functions
;;

