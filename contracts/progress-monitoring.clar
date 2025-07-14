;; Progress Monitoring Contract
;; Tracks sobriety milestones and recovery achievements

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-INVALID-INPUT (err u301))
(define-constant ERR-NOT-FOUND (err u302))
(define-constant ERR-ALREADY-EXISTS (err u303))

;; Data Variables
(define-data-var next-progress-id uint u1)
(define-data-var next-milestone-id uint u1)
(define-data-var next-achievement-id uint u1)

;; Data Maps
(define-map user-progress
  { user-principal: principal }
  {
    sobriety-start-date: uint,
    current-streak: uint,
    longest-streak: uint,
    total-check-ins: uint,
    last-check-in: uint,
    recovery-stage: (string-ascii 50),
    active: bool
  }
)

(define-map daily-check-ins
  { user-principal: principal, date: uint }
  {
    mood-rating: uint,
    stress-level: uint,
    support-used: bool,
    notes: (string-ascii 200),
    verified: bool
  }
)

(define-map milestones
  { milestone-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 300),
    days-required: uint,
    reward-tokens: uint,
    active: bool
  }
)

(define-map user-achievements
  { achievement-id: uint }
  {
    user-principal: principal,
    milestone-id: uint,
    achieved-at: uint,
    days-sober: uint,
    verified: bool
  }
)

(define-map achievement-tokens
  { user-principal: principal }
  { total-tokens: uint }
)

;; Public Functions

;; Initialize user progress tracking
(define-public (start-progress-tracking (sobriety-start-date uint))
  (begin
    (asserts! (is-none (map-get? user-progress { user-principal: tx-sender })) ERR-ALREADY-EXISTS)
    (asserts! (<= sobriety-start-date block-height) ERR-INVALID-INPUT)

    (map-set user-progress
      { user-principal: tx-sender }
      {
        sobriety-start-date: sobriety-start-date,
        current-streak: u0,
        longest-streak: u0,
        total-check-ins: u0,
        last-check-in: u0,
        recovery-stage: "early",
        active: true
      }
    )

    (map-set achievement-tokens
      { user-principal: tx-sender }
      { total-tokens: u0 }
    )

    (ok true)
  )
)

;; Daily check-in
(define-public (daily-check-in (mood-rating uint)
                              (stress-level uint)
                              (support-used bool)
                              (notes (string-ascii 200)))
  (let ((progress-data (unwrap! (map-get? user-progress { user-principal: tx-sender }) ERR-NOT-FOUND))
        (current-date block-height))

    (asserts! (get active progress-data) ERR-NOT-AUTHORIZED)
    (asserts! (and (<= mood-rating u10) (> mood-rating u0)) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? daily-check-ins { user-principal: tx-sender, date: current-date })) ERR-ALREADY-EXISTS)

    ;; Record daily check-in
    (map-set daily-check-ins
      { user-principal: tx-sender, date: current-date }
      {
        mood-rating: mood-rating,
        stress-level: stress-level,
        support-used: support-used,
        notes: notes,
        verified: true
      }
    )

    ;; Update progress
    (let ((new-streak (if (is-eq (get last-check-in progress-data) (- current-date u1))
                         (+ (get current-streak progress-data) u1)
                         u1))
          (new-longest (if (> (+ (get current-streak progress-data) u1) (get longest-streak progress-data))
                          (+ (get current-streak progress-data) u1)
                          (get longest-streak progress-data))))

      (map-set user-progress
        { user-principal: tx-sender }
        (merge progress-data {
          current-streak: new-streak,
          longest-streak: new-longest,
          total-check-ins: (+ (get total-check-ins progress-data) u1),
          last-check-in: current-date
        })
      )
    )

    (ok true)
  )
)

;; Create milestone (admin only)
(define-public (create-milestone (name (string-ascii 100))
                                (description (string-ascii 300))
                                (days-required uint)
                                (reward-tokens uint))
  (let ((milestone-id (var-get next-milestone-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> days-required u0) ERR-INVALID-INPUT)

    (map-set milestones
      { milestone-id: milestone-id }
      {
        name: name,
        description: description,
        days-required: days-required,
        reward-tokens: reward-tokens,
        active: true
      }
    )

    (var-set next-milestone-id (+ milestone-id u1))
    (ok milestone-id)
  )
)

;; Award achievement
(define-public (award-achievement (user-principal principal) (milestone-id uint))
  (let ((achievement-id (var-get next-achievement-id))
        (milestone-data (unwrap! (map-get? milestones { milestone-id: milestone-id }) ERR-NOT-FOUND))
        (progress-data (unwrap! (map-get? user-progress { user-principal: user-principal }) ERR-NOT-FOUND))
        (token-data (unwrap! (map-get? achievement-tokens { user-principal: user-principal }) ERR-NOT-FOUND)))

    (asserts! (get active milestone-data) ERR-INVALID-INPUT)
    (asserts! (>= (get current-streak progress-data) (get days-required milestone-data)) ERR-INVALID-INPUT)

    ;; Record achievement
    (map-set user-achievements
      { achievement-id: achievement-id }
      {
        user-principal: user-principal,
        milestone-id: milestone-id,
        achieved-at: block-height,
        days-sober: (get current-streak progress-data),
        verified: true
      }
    )

    ;; Award tokens
    (map-set achievement-tokens
      { user-principal: user-principal }
      { total-tokens: (+ (get total-tokens token-data) (get reward-tokens milestone-data)) }
    )

    (var-set next-achievement-id (+ achievement-id u1))
    (ok achievement-id)
  )
)

;; Update recovery stage
(define-public (update-recovery-stage (new-stage (string-ascii 50)))
  (let ((progress-data (unwrap! (map-get? user-progress { user-principal: tx-sender }) ERR-NOT-FOUND)))
    (asserts! (get active progress-data) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-stage) u0) ERR-INVALID-INPUT)

    (map-set user-progress
      { user-principal: tx-sender }
      (merge progress-data { recovery-stage: new-stage })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get user progress
(define-read-only (get-user-progress (user-principal principal))
  (map-get? user-progress { user-principal: user-principal })
)

;; Get daily check-in
(define-read-only (get-daily-check-in (user-principal principal) (date uint))
  (map-get? daily-check-ins { user-principal: user-principal, date: date })
)

;; Get milestone
(define-read-only (get-milestone (milestone-id uint))
  (map-get? milestones { milestone-id: milestone-id })
)

;; Get achievement
(define-read-only (get-achievement (achievement-id uint))
  (map-get? user-achievements { achievement-id: achievement-id })
)

;; Get user tokens
(define-read-only (get-user-tokens (user-principal principal))
  (map-get? achievement-tokens { user-principal: user-principal })
)

;; Calculate current sobriety days
(define-read-only (calculate-sobriety-days (user-principal principal))
  (match (map-get? user-progress { user-principal: user-principal })
    progress-data (some (- block-height (get sobriety-start-date progress-data)))
    none
  )
)

;; Get current counters
(define-read-only (get-counters)
  {
    next-progress-id: (var-get next-progress-id),
    next-milestone-id: (var-get next-milestone-id),
    next-achievement-id: (var-get next-achievement-id)
  }
)
