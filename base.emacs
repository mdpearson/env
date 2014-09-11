;
; Copyright (c) 1998-2014 Matthew Pearson <matthewpearson@gmail.com>.
; Based on software (c) 1997 Dartmouth Computer Science Department.
; Based on software (c) 2000 employees of Sun Microsystems.
;
; These scripts are free. There is no warranty; your mileage may vary.
; Visit http://creativecommons.org/licenses/by-nc-sa/4.0/ for more details.
;
; $Id$
; various and sundry emacs customizations, particularly for perl and c
;

; highlight matching parens
(show-paren-mode 1)
; turn on all that cool syntax highlighting, baby!
(global-font-lock-mode t)
(setq font-lock-maximum-decoration t)
; make sure there are newlines in each file, dammit
(setq require-final-newline t)
; uncomment to activate automatic whitespace checking
; (whitespace-global-mode 1)

(custom-set-variables
 '(blink-cursor nil)
 '(display-hourglass nil)
 '(fancy-splash-image nil)
 '(indicate-empty-lines t)
 '(inhibit-startup-message t)
 '(show-trailing-whitespace t)
 '(perl-indent-level 8)
 '(perl-continued-statement-offset 4)
 '(perl-continued-brace-offset 0)
 '(perl-brace-offset -4)
 '(perl-brace-imaginary-offset 0)
 '(perl-label-offset -8)
 '(perl-tab-always-indent t)
 '(sh-indentation 8)
 '(sh-basic-offset 8)
 '(sh-indent-for-if 0)
 '(sh-indent-after-if 8)
 '(sh-indent-for-then 0)
 '(sh-indent-for-else 0)
 '(sh-indent-for-fi 0)
 '(sh-indent-for-for 0)
 '(sh-indent-for-do 0)
 '(sh-indent-after-do 8)
 '(sh-indent-for-done 0)
 '(sh-indent-for-case-label 4)
 '(sh-indent-for-case-alt 8)
 '(sh-indent-for-continuation 4)
 '(sh-indent-after-function 4)
 '(sh-indent-comment 0)
 '(sh-shell-file "/bin/sh")
)

(setq column-number-mode t)

(custom-set-faces
; '(default ((t (:foreground "white" :background "black"))))
 '(font-lock-builtin-face ((t (:foreground "lightsteelblue"))))
 '(font-lock-comment-face ((t (:italic t :foreground "orangered"))))
 '(font-lock-keyword-face ((t (:italic t :foreground "lightskyblue"))))
 '(font-lock-string-face ((t (:foreground "darksalmon"))))
 '(font-lock-variable-name-face ((t (:italic t :foreground "peachpuff"))))
 '(modeline ((t (:foreground "white" :background "#550055"))))
 '(scroll-bar ((t (:background "#484048" :foreground "white"))))

 '(show-paren-match-face ((t
	(:foreground "lightpink" :background "royalblue"))))
 '(show-paren-mismatch-face ((t
	(:foreground "seagreen" :background "greenyellow"))))
 '(trailing-whitespace ((t (:background "skyblue4"))))

 '(fringe ((((class color) (background dark))
	(:background "black" :foreground "thistle4"))))
 '(tooltip ((((class color))
	(:foreground "black" :background "lightyellow"))))
)

(set-face-foreground 'modeline "#550055")
(set-face-background 'modeline "white")

(global-set-key "\M-g"	'goto-line)
(global-set-key "\C-xg"	'goto-line)
(global-set-key "\C-n"	'make-frame)
(global-set-key "\M-w"	'whitespace-cleanup)

(global-set-key "\M-s"	'tags-search)
(global-set-key "\M-r"	'tags-query-replace)
(global-set-key "\M-n"	'tags-loop-continue)

(global-set-key "\M-["	'backward-paragraph)
(global-set-key "\M-]"	'forward-paragraph)
(global-set-key "\M-l"	'font-lock-fontify-block)

(global-set-key "\C-xs" 'save-buffer)
(global-set-key "\C-x%"	'query-replace-regexp)

(global-set-key "\C-x\C-c"	'save-buffers-kill-emacs)
(global-set-key "\C-x\C-x"	'delete-region)

(global-set-key "\C-xc"	'compile)
(setq compile-command	"gmake -k ")

(setq auto-mode-alist
      (append
       '(("\\.C$"    . c++-mode)
	 ("\\.H$"    . c++-mode)
	 ("\\.cc$"   . c++-mode)
	 ("\\.hh$"   . c++-mode)
	 ("\\.c$"    . c-mode)
	 ("\\.h$"    . c-mode)
	 ("\\.hpf$"  . fortran-mode)
	 ("\\.java$" . java-mode)
	 ("makefile" . makefile-mode)
	 ("Makefile" . makefile-mode)
	 ("\\.tex$"  . latex-mode)
	 )
       auto-mode-alist))

(setq completion-ignored-extensions '(".o" ".bbl" "blg" "~" ".dvi" ".log" ".aux" ".lof" ".lot" ".toc" ".o68" ".68" ".syms" ".a"))

(require 'vc)
(setq vc-header-alist
      '((SCCS "#pragma ident\t\"%W""%\t%E""% SMI\"") (RCS "\$Id\$") (CVS "\$Id\$")))
(setq vc-static-header-alist  '(("\\.c$" . "%s")))
(setq shell-file-name '"/bin/sh")

(require 'cc-mode)

; C coding style definition for Solaris source
(defconst sun-internal-c-style
  '((c-basic-offset . 8)
; begin new
    (c-tab-always-indent . t)
    (ispell-check-comments . exclusive)
    (c-label-minimum-indentation . 0)
    (inextern-lang . 0)
; end new
    (c-comment-only-line-offset . 0)
    (c-offsets-alist . ((label . 0)
			(statement-block-intro . +)
			(knr-argdecl-intro . 0)
			(substatement-open . 0)
			(case-label . 0)
			(statement-cont . +)
			; begin new
			(arglist-cont . *)
			(label . 0)
			(arglist-cont-nonempty . *)
			(label . -1000)
			; end new
			)))
  "Sun Internal C indentation style, appropriate for Solaris source code.")

(c-add-style "Sun Internal" sun-internal-c-style nil)

(defun c-set-style-sun-internal ()
  "Set C indentation style as appropriate for Solaris source code."
  (c-set-style "Sun Internal"))

(add-hook 'c-mode-common-hook 'c-set-style-sun-internal)

;EOF __TAGGED__
