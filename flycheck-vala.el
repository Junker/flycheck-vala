;;; flycheck-vala.el --- Flycheck checker for Vala

;; Version: 0.1.0
;; URL: https://github.com/Junker/flycheck-vala
;; Package-Requires: ((flycheck "0.22"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; Flycheck checker for Vala

;;; Code:

(require 'flycheck)

(defun get-value-from-comments (marker-string line-limit)
  "gets a string from the header comments in the current buffer.
TAKEN FROM CSHARP MODE
"

  (let (start search-limit found)
    ;; determine what lines to look in
    (save-excursion
      (save-restriction
        (widen)
        (cond ((> line-limit 0)
               (goto-char (setq start (point-min)))
               (forward-line line-limit)
               (setq search-limit (point)))
              ((< line-limit 0)
               (goto-char (setq search-limit (point-max)))
               (forward-line line-limit)
               (setq start (point)))
              (t ;0 => no limit (use with care!)
               (setq start (point-min))
               (setq search-limit (point-max))))))
    ;; look in those lines
    (save-excursion
      (save-restriction
        (widen)
        (let ((re-string
               (concat "\\b" marker-string "[ \t]*:[ \t]*\\(.+\\)$")))
          (if (and start
                   (< (goto-char start) search-limit)
                   (re-search-forward re-string search-limit 'move))

              (buffer-substring-no-properties
               (match-beginning 1)
               (match-end 1))))))))


;; vala check mode
;; (flycheck-def-option-var flycheck-vala-packages nil vala-check
;;   "A list of additional pakages for valac.

;; The value of this variable is a list of strings, where each
;; string is a package to syntax checking (compiling)."
;;   :type '(repeat (file :tag "Include package"))
;;   :safe #'flycheck-string-list-p
;;   :package-version '(flycheck . "0.15"))

(defun vala-check-set-flycheck()
  "set the flycheck compile arguments from comments in the source file
   example: //flycheck: valac --pkg gtk+-3.0 %f"

  (and (eq major-mode 'vala-mode)
       (let ((cmd-string
              (get-value-from-comments "flycheck" 100)))
         (and cmd-string
              (not (eq cmd-string ""))
              (let* ((cmd (split-string cmd-string " "))
                     (ferf (member "%f" cmd)))
                (and ferf (setcar ferf 'source))
                (put 'vala-check :flycheck-command cmd))))))


(eval-after-load "flycheck"
  '(progn
     (flycheck-define-checker vala-check
       "A Vala language checker.

See URL `https://wiki.gnome.org/Projects/Vala'."

       :command ("valac"
;                 (option-list "--pkg" flycheck-vala-packages)
                 source)
       :error-patterns

       ((error line-start
               (file-name)
               ":" line "." column "-" line "." column
               ": error" (message) line-end)
        (warning line-start
                 (file-name)
                 ":" line "." column "-" line "." column
                 ": warning: " (message) line-end))

       :modes vala-mode)

     (add-hook 'flycheck-before-syntax-check-hook #'vala-check-set-flycheck)
     (add-to-list 'flycheck-checkers 'vala-check)))

(provide 'flycheck-vala)

;;; flycheck-vala.el ends here
