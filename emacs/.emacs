(setq custom-file "~/.emacs.custom.el")
(package-initialize)
(load-file custom-file)
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)

(load "~/.emacs.rc/rc.el")
(load "~/.emacs.rc/custom.el")

(setq tab-width 4)
(setq indent-tabs-mode nil)
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))

(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode)

(set-frame-font "JetBrains Mono" nil t)
(set-face-attribute 'default nil :family "Monospace" :height 120)

(rc/require 'gruber-darker-theme)
(load-theme 'gruber-darker t)

(blink-cursor-mode -1)
(setq make-backup-files nil)

;;; Neon-cat
(rc/require 'nyan-mode)
(require 'nyan-mode)
(nyan-mode 1)

;;; Multiple cursors
(rc/require 'multiple-cursors)
(global-set-key (kbd "C-c C-.") 'mc/edit-lines)
(global-set-key (kbd "M->")     'mc/mark-next-like-this)
(global-set-key (kbd "M-<")     'mc/mark-previous-like-this)

;;; Company
(rc/require 'company)
(require 'company)
(global-company-mode)

;;; Projectile
(rc/require 'projectile)
(require 'projectile)
(projectile-mode +1)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
(setq projectile-project-search-path '("~/projects/" "~/probe/"))

;;; Eglot
(rc/require 'eglot)
(add-hook 'c-mode-hook 'eglot-ensure)
(add-hook 'c++-mode-hook 'eglot-ensure)
(add-hook 'python-mode-hook 'eglot-ensure)

;;; Compilation buffer in the same window
(add-to-list 'display-buffer-alist
             '("\\*compilation\\*"
               (display-buffer-same-window)))

;;; Packages that don't require nfiguration
(rc/require
 'glsl-mode
 'cmake-mode
 'markdown-mode)

;;; LaTeX
(rc/require 'auctex)
(use-package latex
  :ensure auctex
  :hook ((LaTeX-mode . prettify-symbols-mode)))

;;; CDLatex
(rc/require 'cdlatex)
(use-package cdlatex
  :ensure t
  :hook (LaTeX-mode . turn-on-cdlatex)
  :bind (:map cdlatex-mode-map 
              ("<tab>" . cdlatex-tab)))

;;; Helm 
(rc/require 'helm)
(helm-mode 1)
(global-set-key (kbd "M-x") 'helm-M-x)
(global-set-key (kbd "C-x C-f") 'helm-find-files)
(setq helm-M-x-fuzzy-match t)

(when (executable-find "ack-grep")
  (setq helm-grep-default-command "ack-grep -Hn --no-group --no-color %e %p %f"
        helm-grep-default-recurse-command "ack-grep -H --no-group --no-color %e %p %f"))
(setq helm-semantic-fuzzy-match t
      helm-imenu-fuzzy-match    t)

;;; projectile and helm
(rc/require 'helm-projectile)
(require 'helm-projectile)
(helm-projectile-on)
