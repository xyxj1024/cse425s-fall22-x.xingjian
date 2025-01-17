#lang racket
(require 2htdp/image)
(provide shrinking-to-the-right-circles)

(define base-case-color (make-color 144 0 0))
(define recursive-case-color (make-color 0 109 219))

; Xingjian Xuanyuan
(define (shrinking-to-the-right-circles radius n)
  (cond
    [(= n 0) (circle radius "solid" base-case-color)]
    [#t
     (beside (circle radius "outline" recursive-case-color)
             (shrinking-to-the-right-circles (/ (* radius 3) 4) (- n 1)))])) 

(module+ main ; evualated when enclosing module is run directly (that is: not via require)
  (displayln 0)
  (shrinking-to-the-right-circles 128 0)
  (displayln "\n\n1")
  (shrinking-to-the-right-circles 128 1)
  (displayln "\n\n2")
  (shrinking-to-the-right-circles 128 2)
  (displayln "\n\n3")
  (shrinking-to-the-right-circles 128 3)
  (displayln "\n\n4")
  (shrinking-to-the-right-circles 128 4)
  (displayln "\n\n5")
  (shrinking-to-the-right-circles 128 5)
  (displayln "\n\n6")
  (shrinking-to-the-right-circles 128 6)
  )
