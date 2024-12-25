(setq custom-file "~/.emacs.custom.el")
(package-initialize)

(load "~/.emacs.rc/rc.el")
(load "~/.emacs.rc/custom.el")

;;; Setup Emacs text editor
(setq tab-width 4)
(setq indent-tabs-mode nil)
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))

(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode)

;;; Appearance
(set-frame-font "Iosevka NFM" nil t)
(set-face-attribute 'default nil :family "Monospace" :height 120)

(rc/require 'gruber-darker-theme)
(load-theme 'gruber-darker t)

(blink-cursor-mode -1)

;;; Neon-cat
(rc/require 'nyan-mode)
(require 'nyan-mode)
(nyan-mode 1)

;;; No backup files
(setq make-backup-files nil)

;;; Setup other packages
(rc/require 'company)
(require 'company)
(global-company-mode)

;;; projectile
(rc/require 'projectile)
(require 'projectile)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
(define-key projectile-mode-map (kbd "C-c c") 'projectile-compile-project)
(projectile-mode +1)

(setq projectile-project-search-path '("~/projects/"))

;;; ido
(rc/require 'smex 'ido-completing-read+ 'flx-ido)
(require 'ido-completing-read+)

(ido-mode 1)
(ido-everywhere 1)
(ido-ubiquitous-mode 1)

(global-set-key (kbd "M-x") 'smex)

;;; c-mode
(setq-default c-basic-offset 4
              c-default-style '((java-mode . "java")
                                (awk-mode . "awk")
                                (other . "bsd")))

;;; Cmake
(rc/require 'cmake-mode)

;;; Compilation
(add-to-list 'display-buffer-alist
             '("\\*compilation\\*"
               (display-buffer-same-window)))

;;; eglot
(rc/require 'eglot)
(add-hook 'c-mode-hook 'eglot-ensure)
(add-hook 'c++-mode-hook 'eglot-ensure)

;;; multiple cursosr
(rc/require 'multiple-cursors)

(global-set-key (kbd "C-c C-p") 'mc/edit-lines)
(global-set-key (kbd "C->")     'mc/mark-next-like-this)
(global-set-key (kbd "C-<")     'mc/mark-previous-like-this)
(global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)
(global-set-key (kbd "C-\"")    'mc/skip-to-next-like-this)
(global-set-key (kbd "C-:")     'mc/skip-to-previous-like-this)

;;; LaTeX
(rc/require 'auctex)
(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq-default TeX-master nil)

(add-hook 'LaTeX-mode-hook 'turn-on-reftex)
(setq reftex-plug-into-AUCTeX t)

;;; Snippets
(rc/require 'yasnippet)
(require 'yasnippet)
(yas-global-mode 1)
(setq yas-snippet-dirs
      '( "~/snippets/" ))

;;; Packages that don't require nfiguration
(rc/require
 'glsl-mode
 'cmake-mode
 'markdown-mode)

(load-file custom-file)
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
