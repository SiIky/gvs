(module
  gvs
  (
   gvs->string
   gvs->tree
   gvs-tree->string
   gvs-tree-write
   gvs-write
   )

  (import scheme)
  (import chicken.base)
  (import chicken.port)
  (import matchable)
  (import srfi-1)

  (define (sngl? l)
    (and (pair? l)
         (not (null? l))
         (null? (cdr l))))

  (define make-opt cons)

  (define (opt-key opt) (car opt))
  (define (opt-val opt) (cdr opt))

  (define (opt->pair opt)
    (define (safe-opt-key opt)
      (and (pair? opt) (atom? (car opt)) (car opt)))
    (define (safe-opt-val opt)
      (and (pair? opt)
           (not (sngl? opt))
           (or (atom? (cdr opt))
               (sngl? (cdr opt)))
           (if (atom? (cdr opt))
               (cdr opt)
               (cadr opt))))
    (make-opt (safe-opt-key opt) (safe-opt-val opt)))

  (define (opts->pairs opts) (map opt->pair opts))
  (define (empty-sets) (make-sets '() '() '()))
  (define (make-sets graph edge node) `(,graph ,edge ,node))
  (define (graph-sets sets) (first  sets))
  (define (edge-sets  sets) (second sets))
  (define (node-sets  sets) (third  sets))
  (define (set-graph-sets sets graph-sets) (make-sets graph-sets (edge-sets sets) (node-sets sets)))
  (define (set-edge-sets  sets edge-sets)  (make-sets (graph-sets sets) edge-sets (node-sets sets)))
  (define (set-node-sets  sets node-sets)  (make-sets (graph-sets sets) (edge-sets sets) node-sets))
  (define (update-sets sets key val)
    (define (sets-no-key sets key)
      ; filter (not . (== key) . opt-key) sets
      (filter (lambda (s) (not (eq? key (opt-key s)))) sets))

    (let ((sets (sets-no-key sets key)))
      (if val
          (let loop ((sets sets))
            (cond
              ((null? sets)
               `(,(make-opt key val)))
              ((eq? key (opt-key (car sets)))
               (cons (make-opt key val) (cdr sets)))
              (else
                (cons (car sets) (loop (cdr sets))))))
          sets)))

  (define (merge-sets local global)
    (foldl (lambda (ret opt) (update-sets ret (opt-key opt) (opt-val opt)))
           global local))

  (define (new-ret ret res)
    (if (car res)
        (cons (car res) ret)
        ret))

  (define (gvs->tree gvs)
    (define (gvs->tree-iter body sets ret)
      (define (switch args sets)

        (define (settings sets args)
          (define (graph opts sets) (set-graph-sets sets (merge-sets opts (graph-sets sets))))
          (define (edge  opts sets) (set-edge-sets  sets (merge-sets opts (edge-sets  sets))))
          (define (node  opts sets) (set-node-sets  sets (merge-sets opts (node-sets  sets))))

          (foldl
            (lambda (sets elem)
              (match elem
                     (('graph . opts) (graph (opts->pairs opts) sets))
                     (('edge  . opts) (edge  (opts->pairs opts) sets))
                     (('node  . opts) (node  (opts->pairs opts) sets))
                     (_ (error 'settings "Must be one of `graph`, `edge` or `node`" elem))))
            sets args))

        (define (nodes sets nodes)
          `(,(cons 'nodes (map (cut cons <> (node-sets sets)) nodes)) . ,sets))

        (define (node sets node)
          `((node ,(car node) ,(merge-sets (opts->pairs (cdr node)) (node-sets sets))) . ,sets))

        (define (edge t global-sets from to . local-sets)
          `((,t ,from ,to ,@(merge-sets (opts->pairs local-sets) (edge-sets global-sets))) . ,global-sets))

        (match args
               (() `(#f . ,sets))
               (('settings . args) `(#f . ,(settings sets args)))
               (('nodes    . args) (nodes sets args))
               (('node     . args) (node sets args))
               (('->       . args) (apply edge '-> sets args))
               (('--       . args) (apply edge '-- sets args))
               (_ (error 'switch "Must be one of `settings`, `nodes`, `node`, `->` or `--`" args))))

      (match body
             (() `((graph . ,(graph-sets sets)) . ,(reverse ret)))
             ((head . tail)
              (let ((res (switch head sets)))
                (gvs->tree-iter tail (cdr res) (new-ret ret res))))))

    (define (gvs->tree-int t n . body)
      `(,t ,n ,@(gvs->tree-iter body (empty-sets) '())))

    (apply gvs->tree-int gvs))

  (define (gvs-tree-write gvs-tree)
    (define (gvs-tree-write-int t n . body)
      (define (outter-printer elem)
        (define (opt-printer opt)
          (display " ")
          (write (opt-key opt))
          (display "=")
          (write (opt-val opt)))

        (define (opts-printer opts)
          (for-each opt-printer opts))

        (define (print-opts-between-squares sets)
          (when (not (null? sets))
            (display " [")
            (opts-printer sets)
            (display " ];\n")))

        (define (graph-printer sets)
          (when (not (null? sets))
            (display "\tgraph")
            (print-opts-between-squares sets)))

        (define (nodes-printer nodes)
          (define (node-printer nd-lbl . sets)
            (display "\t")
            (write nd-lbl)
            (print-opts-between-squares sets))

          (for-each (cut apply node-printer <>) nodes))

        (define (node-printer node sets)
          (display "\t")
          (write node)
          (print-opts-between-squares sets))

        (define (edge-printer t from to sets)
          (display "\t")
          (write from)
          (display " ")
          (display t)
          (display " ")
          (write to)
          (print-opts-between-squares sets))

        (match elem
               (() #f)
               (('graph . sets) (graph-printer sets))
               (('nodes . nodes) (nodes-printer nodes))
               (('node . node) (apply node-printer node))
               (('-> . (from . (to . sets))) (edge-printer '-> from to sets))
               (('-- . (from . (to . sets))) (edge-printer '-- from to sets))
               (_ (error 'gvs-tree-write "Must be one of `graph`, `nodes`, `node`, `->` or `--`" elem))))

      (print t " " n)
      (print "{")
      (for-each outter-printer body)
      (print "}"))

    (apply gvs-tree-write-int gvs-tree))

  (define (gvs-tree->string gvs-tree)
    (with-output-to-string (lambda () (gvs-tree-write gvs-tree))))

  (define (gvs->string gvs)
    (gvs-tree->string (gvs->tree gvs)))

  (define (gvs-write gvs)
    (gvs-tree-write (gvs->tree gvs))))
