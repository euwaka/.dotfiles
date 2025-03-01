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

(global-set-key (kbd "C-x C-r") 'eval-buffer)

;; setup the Nerd Font
(set-frame-font "FiraCode Nerd Font Mono" nil t)

;; setup relative numbers and goto-line
(rc/require 'goto-line-preview)
(global-set-key (kbd "C-c C-a") 'goto-line-preview-relative)
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode t)
(setq-default display-fill-column-indicator-column 120)
(global-set-key (kbd "C-c C-s") 'display-fill-column-indicator-mode)

(rc/require 'gruber-darker-theme)
(load-theme 'gruber-darker t)
(blink-cursor-mode -1)
(setq make-backup-files nil)

;; Fold-mode
(rc/require 'origami)
(global-set-key (kbd "C-c C-<tab>") 'origami-close-all-nodes)
(global-set-key (kbd "C-<tab>") 'origami-toggle-node)
(global-set-key (kbd "C-c C-r") 'origami-reset)

;; Shed some light on the cursor
(rc/require 'beacon)
(beacon-mode 1)

;;; Multiple cursors
(rc/require 'multiple-cursors)
(global-set-key (kbd "C-c C-.") 'mc/edit-lines)
(global-set-key (kbd "M->")     'mc/mark-next-like-this)
(global-set-key (kbd "M-<")     'mc/mark-previous-like-this)

;;; Company
(rc/require 'company)
(require 'company)
(add-hook 'after-init-hook 'global-company-mode)

;;; custom status bar
(rc/require 'doom-modeline)
(use-package doom-modeline
  :ensure t
  :config
  (doom-modeline-mode 1))

(rc/require 'nyan-mode)
(nyan-mode)

(setq doom-modeline-icon nil)
(setq doom-modeline-major-mode-icon nil)
(setq doom-modeline-major-mode-color-icon nil)
(setq doom-modeline-project-name t)
(setq doom-modeline-buffer-encoding nil)

;;; Projectile
(rc/require 'projectile)
(require 'projectile)
(projectile-mode +1)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
(setq projectile-project-search-path '("~/projects"))
(projectile-add-known-project "~/.dotfiles")

;;; Compilation buffer in the same window
(add-to-list 'display-buffer-alist
             '("\\*compilation\\*"
               (display-buffer-same-window)))
;;; Header
(setq-default header-line-format
  '((:eval
     (propertize " ★ 无论空虚的，我就是我, 无论任何事情,都是我一切的基础. ★ Sexy as always ★ "
                 'face '(:foreground "#c4c4c4" :background nil :weight bold :height 1.0 :position )))))
(setq initial-scratch-message ";; Don't Complain!")
(setq inhibit-splash-screen t)

;;; Flycheck
(rc/require 'flycheck)
(global-flycheck-mode)

;;; Helm
(rc/require 'helm 'helm-projectile 'helm-make)
(helm-mode 1)
(global-set-key (kbd "M-x") 'helm-M-x)

(global-set-key (kbd "C-c m") 'helm-make)

(require 'helm-projectile)
(helm-projectile-on)
(global-set-key (kbd "C-x C-f") 'helm-find-files)
(global-set-key (kbd "C-x p f") 'helm-projectile-find-file)
(global-set-key (kbd "C-x p p") 'helm-projectile-switch-project)
(global-set-key (kbd "C-x p d") 'helm-projectile-find-dir)
(global-set-key (kbd "C-x p s") 'helm-projectile-grep)
(global-set-key (kbd "C-x p b") 'helm-projectile-switch-to-buffer)

;;; LSP
(rc/require 'lsp-mode 'lsp-ui 'helm-lsp 'dap-mode 'ebrowse)
(require 'lsp-mode)

(use-package lsp-ui :commands lsp-ui-mode)
(use-package helm-lsp :commands helm-lsp-workspace-symbol)
(use-package dap-mode)

(add-hook 'c-mode-hook #'lsp)
(add-hook 'python-mode-hook #'lsp)
(add-hook 'markdown-mode-hook #'lsp)

(setq lsp-clients-clangd-args '("--compile-commands-dir=./"))

;;; Magit
(rc/require 'magit)

;;; LaTeX


(provide '.emacs)
;;; .emacs ends here
