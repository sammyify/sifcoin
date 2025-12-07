;; title: sifcoin
;; version: 1.0.0
;; summary: SIP-010 compatible fungible token for the Sifcoin project
;; description: A simple fungible token implementation following the SIP-010 standard with basic admin-controlled minting.

;; --------------------------------------------
;; TRAIT IMPORTS
;; --------------------------------------------
;; NOTE: For local development we omit an external SIP-010 trait reference so that
;; `clarinet check` can run without remote contract resolution. You can add a
;; concrete ft-trait implementation here when deploying on a real network.
;; --------------------------------------------
;; CONSTANTS
;; --------------------------------------------
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INSUFFICIENT-ALLOWANCE (err u102))
(define-constant ERR-RECIPIENT-IS-SENDER (err u103))

(define-constant CONTRACT-OWNER tx-sender)

(define-constant TOKEN-NAME (some "Sifcoin"))
(define-constant TOKEN-SYMBOL (some "SIF"))
(define-constant TOKEN-DECIMALS u6)

;; --------------------------------------------
;; DATA VARIABLES
;; --------------------------------------------

;; Total supply of SIF (in smallest units, considering TOKEN-DECIMALS)
(define-data-var total-supply uint u0)

;; Balances: principal -> uint
(define-map balances { owner: principal } { balance: uint })

;; Allowances: {owner, spender} -> uint
(define-map allowances { owner: principal, spender: principal } { amount: uint })

;; --------------------------------------------
;; PRIVATE HELPERS
;; --------------------------------------------

(define-private (is-owner (who principal))
  (is-eq who CONTRACT-OWNER)
)

(define-private (get-balance (owner principal))
  (default-to u0
    (get balance (map-get? balances { owner: owner }))
  )
)

(define-private (set-balance (owner principal) (amount uint))
  (map-set balances { owner: owner } { balance: amount })
)

;; internal helper for looking up allowance without creating an interdependent cycle
(define-private (get-allowance-internal (owner principal) (spender principal))
  (default-to u0
    (get amount (map-get? allowances { owner: owner, spender: spender }))
  )
)

(define-private (set-allowance (owner principal) (spender principal) (amount uint))
  (map-set allowances { owner: owner, spender: spender } { amount: amount })
)

(define-private (transfer-internal (sender principal) (recipient principal) (amount uint))
  (begin
    (if (is-eq sender recipient)
        ERR-RECIPIENT-IS-SENDER
        (let
          (
            (sender-balance (get-balance sender))
            (recipient-balance (get-balance recipient))
          )
          (if (< sender-balance amount)
              ERR-INSUFFICIENT-BALANCE
              (begin
                (set-balance sender (- sender-balance amount))
                (set-balance recipient (+ recipient-balance amount))
                (ok true)
              )
          )
        )
    )
  )
)

;; --------------------------------------------
;; SIP-010 REQUIRED PUBLIC FUNCTIONS
;; --------------------------------------------

(define-public (transfer (recipient principal) (amount uint) (memo (optional (buff 34))))
  (transfer-internal tx-sender recipient amount)
)

(define-public (transfer-from (sender principal) (recipient principal) (amount uint) (memo (optional (buff 34))))
  (let
    ((current-allowance (get-allowance-internal sender tx-sender)))
    (if (< current-allowance amount)
        ERR-INSUFFICIENT-ALLOWANCE
        (let ((transfer-result (transfer-internal sender recipient amount)))
          (match transfer-result
            success
              (begin
                (set-allowance sender tx-sender (- current-allowance amount))
                (ok true)
              )
            error transfer-result
          )
        )
    )
  )
)

(define-public (approve (spender principal) (amount uint))
  (begin
    (set-allowance tx-sender spender amount)
    (ok true)
  )
)

(define-public (mint (recipient principal) (amount uint))
  (if (is-owner tx-sender)
      (let
        (
          (recipient-balance (get-balance recipient))
          (current-supply (var-get total-supply))
        )
        (begin
          (set-balance recipient (+ recipient-balance amount))
          (var-set total-supply (+ current-supply amount))
          (ok true)
        )
      )
      ERR-NOT-AUTHORIZED
  )
)

;; --------------------------------------------
;; SIP-010 READ-ONLY FUNCTIONS
;; --------------------------------------------

(define-read-only (get-name)
  TOKEN-NAME
)

(define-read-only (get-symbol)
  TOKEN-SYMBOL
)

(define-read-only (get-decimals)
  TOKEN-DECIMALS
)

(define-read-only (get-total-supply)
  (var-get total-supply)
)

(define-read-only (get-balance-of (owner principal))
  (get-balance owner)
)

(define-read-only (get-allowance (owner principal) (spender principal))
  (get-allowance-internal owner spender)
)
