(import chicken.process-context)
(import gvs)

(define (main args)
  (let ((gvs (read)))
    (let ((tree (gvs->tree gvs)))
      (print (gvs->string gvs))
      (print (gvs-tree->string tree))
      (gvs-write gvs)
      (newline)
      (gvs-tree-write tree))))

(main (command-line-arguments))
