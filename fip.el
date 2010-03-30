;;; fip.el --- Interface to the FIP radio.
;;;
;;; $Id: fip.el,v 1.4 2001/11/05 15:37:47 giraud Exp $
;;; $Author: giraud $
;;; $Revision: 1.4 $
;;;
;;; Author: Manuel Giraud <manuel.giraud@inria.fr>
;;; Copyright: (C) 2001 Manuel Giraud
;;
;;     This program is free software; you can redistribute it and/or
;;     modify it under the terms of the GNU General Public License as
;;     published by the Free Software Foundation; either version 2 of
;;     the License, or (at your option) any later version.
;;     
;;     This program is distributed in the hope that it will be useful,
;;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;;     GNU General Public License for more details.
;;     
;;     You should have received a copy of the GNU General Public
;;     License along with this program; if not, write to the Free
;;     Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
;;     MA 02111-1307, USA.
;;
;; Please send suggestions and bug reports to <manuel.giraud@inria.fr>.
;; The latest version of this package should be available at
;;
;;     <URL:http://www-sor.inria.fr/~giraud/emacs/fip.el>

;;; Commentary:

;; This package offers you a function `fip' which pop up a new buffer
;; with songs that are played on FIP (a french radio I used to listen,
;; for details see
;; <URL:http://www.radio-france.fr/chaines/fip/direct/>).
;; 
;; I think that it is a really "personnal" package but I wanted to
;; provide it just in case...
;;
;; To install:
;;    0. Install the url package
;;    1. Put this file in your `load-path'
;;    2. Put (require 'fip) in your .emacs
;;    3. M-x fip

;;; Code:

(require 'url)

;; The FIP http server url.
(defconst fip-url
  "http://www.radio-france.fr/chaines/fip/direct/"
  "The FIP http server url.")

;; A pattern used to go to the good place in the html file.
(defconst fip-next-pattern "A venir"
  "A pattern to find the next song.")

;; A pattern used to remove junk.
(defconst fip-junk-pattern "<[^>]+>[ \t\n]*"
  "A junk pattern.")

;; A patter used to extract infos between junk.
(defconst fip-info-pattern "\\([^<]+\\)"
  "An info pattern.")

;; A list that contains the songs and some function to access it.
;; Nota: (length fip-songs-list) -> 3
(defvar fip-songs-list (make-list 3 '())
  "A list used to store the list of songs. `car' of this list is the
current song, `cadr' and `caddr' are the next ones. Each entry of this
list is a list in which `car' is the time, `cadr' is the artist's name
and `caddr' is the song's title.")

;; A fip-mode to add some eye candy.
(define-derived-mode fip-mode fundamental-mode "FIP"
  "Major mode to display song's title fetched from FIP server."
  (setq fip-font-lock-keywords
	(list
	 (list
	  (concat
	   ;; Time
	   "^\\([^:]+\\):"
	   ;; Spaces
	   "[ \t]*"
	   ;; Song's title
	   "\\(\"[^\"]+\"\\)"
	   ;; Spaces -- a connecting word -- spaces
	   "[ \t]*[^ \t]+[ \t]*"
	   ;; Artist name
	   "\\(.*$\\)")
	  '(1 font-lock-keyword-face)
	  '(2 font-lock-string-face)
	  '(3 font-lock-comment-face nil t))))
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(fip-font-lock-keywords nil t)))

;; This function retrieve the HTML page and clean it to fill the
;; `fip-songs-list'.
(defun fip-fill-songs-list ()
  (with-temp-buffer 
    (insert-buffer (url-retrieve-synchronously fip-url))
    
    ;; Focus on the important line.
    (when (re-search-forward fip-next-pattern nil t)
      (beginning-of-line))
    
    ;; Get the current song and artist.
    (when (re-search-forward 
	   (concat
	    ;; Junk
	    fip-junk-pattern
	    ;; Artist name
	    fip-info-pattern
	    ;; Some more junk
	    fip-junk-pattern
	    fip-junk-pattern
	    ;; Song name
	    fip-info-pattern)
	   nil t)
      (setcar fip-songs-list 
	      (list 0 
		    (capitalize (match-string 1)) 
		    (capitalize (match-string 2)))))
    
    ;; Goto "A venir"
    (when (re-search-forward fip-next-pattern nil t)
      (goto-char (match-end 0)))

    ;; Get the next song, time and artist.
    (when (re-search-forward 
	   (concat
	    ;; Junk
	    fip-junk-pattern
	    fip-junk-pattern
	    ;; Time
	    fip-info-pattern
	    ;; Some more junk
	    fip-junk-pattern
	    ;; Artist name
	    fip-info-pattern
	    ;; Guess what ?
	    fip-junk-pattern
	    ;; Song name
	    fip-info-pattern)
	   nil t)
      (setcar (cdr fip-songs-list) 
	      (list (match-string 1) 
		    (capitalize (match-string 2)) 
		    (capitalize (match-string 3)))))

    ;; Get the next next song, time and artist.
    (when (re-search-forward 
	   (concat
	    ;; Lot of junk
	    fip-junk-pattern
	    fip-junk-pattern
	    fip-junk-pattern
	    ;; Time
	    fip-info-pattern
	    ;; Some more junk
	    fip-junk-pattern
	    ;; Artist name
	    fip-info-pattern
	    ;; Guess what ?
	    fip-junk-pattern
	    ;; Song name
	    fip-info-pattern)
	   nil t)
      (setcar (cddr fip-songs-list) 
	      (list (match-string 1) 
		    (capitalize (match-string 2))
		    (capitalize (match-string 3)))))))

;; The only interactive function of this package : just use it.
(defun fip ()
  "Pop up a new buffer with songs currently played on FIP."
  (interactive)
  (fip-fill-songs-list)
  (with-output-to-temp-buffer "*FIP*"

    ;; Print the current song.
    (let ((song (car fip-songs-list)))
      (princ "Maintenant: \"")
      (princ (caddr song))
      (princ "\" par ")
      (princ (cadr song))
      (princ "\n"))
    ;; Print the next song.
    (let ((song (cadr fip-songs-list)))
      (princ (car song))
      (princ ": \"")
      (princ (caddr song))
      (princ "\" par ")
      (princ (cadr song))
      (princ "\n"))
    ;; Print the next next song.
    (let ((song (caddr fip-songs-list)))
      (princ (car song))
      (princ ": \"")
      (princ (caddr song))
      (princ "\" par ")
      (princ (cadr song)))
    
    ;; Setting mode
    (save-excursion
      (set-buffer "*FIP*")
      (fip-mode)
      (temp-buffer-resize-mode)
      (turn-on-font-lock)
      (set-buffer-modified-p nil)
      (setq buffer-read-only t))))

(provide 'fip)

;;; end of fip.el
