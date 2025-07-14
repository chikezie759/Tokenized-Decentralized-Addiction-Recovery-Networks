;; Family Support Contract
;; Provides resources and guidance for affected family members

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-INVALID-INPUT (err u401))
(define-constant ERR-NOT-FOUND (err u402))
(define-constant ERR-ALREADY-EXISTS (err u403))
(define-constant ERR-CONSENT-REQUIRED (err u404))

;; Data Variables
(define-data-var next-family-id uint u1)
(define-data-var next-resource-id uint u1)
(define-data-var next-session-id uint u1)

;; Data Maps
(define-map family-members
  { family-id: uint }
  {
    family-principal: principal,
    recovery-user: principal,
    relationship: (string-ascii 50),
    consent-given: bool,
    access-level: (string-ascii 20),
    registered-at: uint,
    active: bool
  }
)

(define-map family-resources
  { resource-id: uint }
  {
    title: (string-ascii 200),
    description: (string-ascii 500),
    resource-type: (string-ascii 50),
    content-url: (string-ascii 200),
    access-level: (string-ascii 20),
    created-at: uint,
    active: bool
  }
)

(define-map support-sessions
  { session-id: uint }
  {
    session-type: (string-ascii 50),
    facilitator: principal,
    scheduled-time: uint,
    duration: uint,
    max-participants: uint,
    current-participants: uint,
    status: (string-ascii 20)
  }
)

(define-map session-participants
  { session-id: uint, participant: principal }
  {
    registered-at: uint,
    attended: bool,
    feedback-rating: uint
  }
)

(define-map progress-sharing-consent
  { recovery-user: principal, family-member: principal }
  {
    consent-given: bool,
    consent-date: uint,
    sharing-level: (string-ascii 20)
  }
)

(define-map family-principals
  { principal: principal }
  { family-id: uint }
)

;; Public Functions

;; Register family member
(define-public (register-family-member (recovery-user principal)
                                      (relationship (string-ascii 50)))
  (let ((family-id (var-get next-family-id)))
    (asserts! (is-none (map-get? family-principals { principal: tx-sender })) ERR-ALREADY-EXISTS)
    (asserts! (> (len relationship) u0) ERR-INVALID-INPUT)

    (map-set family-members
      { family-id: family-id }
      {
        family-principal: tx-sender,
        recovery-user: recovery-user,
        relationship: relationship,
        consent-given: false,
        access-level: "basic",
        registered-at: block-height,
        active: true
      }
    )

    (map-set family-principals
      { principal: tx-sender }
      { family-id: family-id }
    )

    (var-set next-family-id (+ family-id u1))
    (ok family-id)
  )
)

;; Grant progress sharing consent (by recovery user)
(define-public (grant-progress-consent (family-member principal) (sharing-level (string-ascii 20)))
  (begin
    (asserts! (> (len sharing-level) u0) ERR-INVALID-INPUT)

    (map-set progress-sharing-consent
      { recovery-user: tx-sender, family-member: family-member }
      {
        consent-given: true,
        consent-date: block-height,
        sharing-level: sharing-level
      }
    )

    ;; Update family member access level
    (match (map-get? family-principals { principal: family-member })
      family-data
        (match (map-get? family-members { family-id: (get family-id family-data) })
          member-data
            (if (is-eq (get recovery-user member-data) tx-sender)
              (map-set family-members
                { family-id: (get family-id family-data) }
                (merge member-data {
                  consent-given: true,
                  access-level: sharing-level
                })
              )
              false
            )
          false
        )
      false
    )

    (ok true)
  )
)

;; Create family resource (admin only)
(define-public (create-resource (title (string-ascii 200))
                               (description (string-ascii 500))
                               (resource-type (string-ascii 50))
                               (content-url (string-ascii 200))
                               (access-level (string-ascii 20)))
  (let ((resource-id (var-get next-resource-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)

    (map-set family-resources
      { resource-id: resource-id }
      {
        title: title,
        description: description,
        resource-type: resource-type,
        content-url: content-url,
        access-level: access-level,
        created-at: block-height,
        active: true
      }
    )

    (var-set next-resource-id (+ resource-id u1))
    (ok resource-id)
  )
)

;; Schedule support session
(define-public (schedule-session (session-type (string-ascii 50))
                                (scheduled-time uint)
                                (duration uint)
                                (max-participants uint))
  (let ((session-id (var-get next-session-id)))
    (asserts! (> (len session-type) u0) ERR-INVALID-INPUT)
    (asserts! (> scheduled-time block-height) ERR-INVALID-INPUT)
    (asserts! (> duration u0) ERR-INVALID-INPUT)
    (asserts! (> max-participants u0) ERR-INVALID-INPUT)

    (map-set support-sessions
      { session-id: session-id }
      {
        session-type: session-type,
        facilitator: tx-sender,
        scheduled-time: scheduled-time,
        duration: duration,
        max-participants: max-participants,
        current-participants: u0,
        status: "scheduled"
      }
    )

    (var-set next-session-id (+ session-id u1))
    (ok session-id)
  )
)

;; Register for support session
(define-public (register-for-session (session-id uint))
  (let ((session-data (unwrap! (map-get? support-sessions { session-id: session-id }) ERR-NOT-FOUND))
        (family-data (unwrap! (map-get? family-principals { principal: tx-sender }) ERR-NOT-AUTHORIZED)))

    (asserts! (is-eq (get status session-data) "scheduled") ERR-INVALID-INPUT)
    (asserts! (< (get current-participants session-data) (get max-participants session-data)) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? session-participants { session-id: session-id, participant: tx-sender })) ERR-ALREADY-EXISTS)

    (map-set session-participants
      { session-id: session-id, participant: tx-sender }
      {
        registered-at: block-height,
        attended: false,
        feedback-rating: u0
      }
    )

    (map-set support-sessions
      { session-id: session-id }
      (merge session-data { current-participants: (+ (get current-participants session-data) u1) })
    )

    (ok true)
  )
)

;; Mark session attendance
(define-public (mark-attendance (session-id uint) (participant principal))
  (let ((session-data (unwrap! (map-get? support-sessions { session-id: session-id }) ERR-NOT-FOUND))
        (participant-data (unwrap! (map-get? session-participants { session-id: session-id, participant: participant }) ERR-NOT-FOUND)))

    (asserts! (is-eq (get facilitator session-data) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status session-data) "in-progress") ERR-INVALID-INPUT)

    (map-set session-participants
      { session-id: session-id, participant: participant }
      (merge participant-data { attended: true })
    )

    (ok true)
  )
)

;; Submit session feedback
(define-public (submit-feedback (session-id uint) (rating uint))
  (let ((participant-data (unwrap! (map-get? session-participants { session-id: session-id, participant: tx-sender }) ERR-NOT-FOUND)))
    (asserts! (get attended participant-data) ERR-NOT-AUTHORIZED)
    (asserts! (and (<= rating u5) (> rating u0)) ERR-INVALID-INPUT)

    (map-set session-participants
      { session-id: session-id, participant: tx-sender }
      (merge participant-data { feedback-rating: rating })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get family member information
(define-read-only (get-family-member (family-id uint))
  (map-get? family-members { family-id: family-id })
)

;; Get resource information
(define-read-only (get-resource (resource-id uint))
  (map-get? family-resources { resource-id: resource-id })
)

;; Get session information
(define-read-only (get-session (session-id uint))
  (map-get? support-sessions { session-id: session-id })
)

;; Get session participant information
(define-read-only (get-participant (session-id uint) (participant principal))
  (map-get? session-participants { session-id: session-id, participant: participant })
)

;; Get progress sharing consent
(define-read-only (get-consent (recovery-user principal) (family-member principal))
  (map-get? progress-sharing-consent { recovery-user: recovery-user, family-member: family-member })
)

;; Get family ID by principal
(define-read-only (get-family-id (family-principal principal))
  (map-get? family-principals { principal: family-principal })
)

;; Check if family member has access to progress
(define-read-only (has-progress-access (recovery-user principal) (family-member principal))
  (match (map-get? progress-sharing-consent { recovery-user: recovery-user, family-member: family-member })
    consent-data (get consent-given consent-data)
    false
  )
)

;; Get current counters
(define-read-only (get-counters)
  {
    next-family-id: (var-get next-family-id),
    next-resource-id: (var-get next-resource-id),
    next-session-id: (var-get next-session-id)
  }
)
