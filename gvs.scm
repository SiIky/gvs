(module
  gvs
  ()

  (import scheme)
  (import chicken.base)
  (import matchable)

  (define (graph-sets sets) (car   sets))
  (define (edge-sets  sets) (cadr  sets))
  (define (node-sets  sets) (caddr sets))
  (define (merge-sets local global)
    ; TODO:
    local)

  (define (new-ret ret res)
    (if (car res)
        (cons res ret)
        ret))

  (define (di/graph t n . body)
    (define (switch args sets)
      (define (settings sets args)
        ; TODO:
        (define (graph opts sets) `(#f . ,sets))
        (define (edge opts sets)  `(#f . ,sets))
        (define (node opts sets)  `(#f . ,sets))

        (let loop ((args args)
                   (sets sets)
                   (ret '()))
          (if (null? args)
              `(,ret . ,sets)
              (let ((res (match (car args)
                                (('graph . opts) (graph opts sets))
                                (('edge  . opts) (edge opts sets))
                                (('node  . opts) (node opts sets))
                                (_ (error args)))))
                (loop (cdr args) (cdr res) (new-ret ret res))))))

      (define (nodes sets nodes)
        (let ((node-sets (node-sets sets)))
          (map (lambda (node) `(,node sets) nodes))))

      (define (-> global-sets from to . local-sets)
        (let ((sets (merge-sets local-sets (edge-sets global-sets))))
          `(,from ,to ,sets)))

      (if (or (null? args)
              (atom? args))
          `(#f . sets)
          (let ((tag (car args))
                (args (cdr args)))
            (match tag
                   ('settings (settings sets args))
                   ('nodes    (nodes    sets args))
                   ('->       (apply -> sets args))
                   (_         (error args))))))


    (define (di/graph-iter body sets ret)
      (match body
             (() (reverse ret))
             ((head . tail)
              (let ((res (switch head sets)))
                (di/graph-iter tail (cdr res) (new-ret ret (car res))))))))
  )
