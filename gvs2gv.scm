(import chicken.file)
(import chicken.file.posix)
(import chicken.pathname)
(import chicken.process-context)
(import optimism)
(import srfi-1)
(import srfi-13)
(import gvs)

(define (proc-file? fname orig-ext targ-ext)
  (let ((targ-fname (pathname-replace-extension fname targ-ext)))
    (and (string-suffix? orig-ext fname)
         (file-exists? fname)
         (or (not (file-exists? targ-fname))
             (> (file-modification-time fname)
                (file-modification-time targ-fname))))))

(define (main args)
  (if (null? args) ; read from stdin, write to stdout
      (let ((gvs-tree (read)))
        (unless (eof-object? gvs-tree)
          (gvs-write (read))))
      (let ((files (filter (cut proc-file? <> "gvs" "gv") args)))
        (for-each
          (lambda (file)
            (with-output-to-file
              (pathname-replace-extension file "gv")
              (lambda ()
                (with-input-from-file
                  file
                  (lambda ()
                    (gvs-write (read)))))))
          files))))

(main (command-line-arguments))
