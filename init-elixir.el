(require 'flycheck-credo)
;; (setq flycheck-elixir-credo-strict t)
(eval-after-load 'flycheck
  '(flycheck-credo-setup))

(add-hook 'elixir-format-hook (lambda ()
                                (if (projectile-project-p)
                                    (setq elixir-format-arguments
                                          (list "--dot-formatter"
                                                (concat (locate-dominating-file buffer-file-name ".formatter.exs") ".formatter.exs")))
                                  (setq elixir-format-arguments nil))))

(add-hook 'elixir-mode-hook
          (lambda ()
            (flycheck-mode)
            (lsp-elixir-enable)
            (add-hook 'before-save-hook #'elixir-maybe-format nil t)
            ))

(defun elixir-maybe-format ()
  (interactive)
  (elixir-format)
  )

(defun flycheck-credo--working-directory (&rest _ignored)
  "Find directory with mix.exs."
  (and buffer-file-name
       (locate-dominating-file buffer-file-name "mix.exs")))

(flycheck-define-checker elixir-mix
  "An Elixir syntax checker using the Elixir interpreter.

See URL `http://elixir-lang.org/'."
  :command ("mix"
            "compile"
            source-original)
  :working-directory flycheck-credo--working-directory
  :predicate
  (lambda () (and buffer-file-name
             (member (file-name-extension buffer-file-name) '("ex" "exs"))
             (locate-dominating-file buffer-file-name "mix.exs")))
  :error-patterns
  ((error line-start "** (" (zero-or-more not-newline) ") "
          (zero-or-more not-newline) ":" line ": " (message) line-end)
   (warning line-start
            "warning: "
            (message)
            "\n"
            (one-or-more whitespace)
            (file-name)
            ":"
            line
            line-end))
  :modes elixir-mode
  :next-checkers ((warning . elixir-credo)))

(add-to-list 'flycheck-checkers 'elixir-mix)


(require 'lsp-mode)

(require 'lsp-ui)
(add-hook 'lsp-mode-hook 'lsp-ui-mode)
(add-hook 'elixir-mode-hook 'flycheck-mode)

(require 'lsp-ui-flycheck)
(setq lsp-inhibit-message t)
(with-eval-after-load 'lsp-mode
  (add-hook 'lsp-after-open-hook (lambda () (lsp-ui-flycheck-enable 1))))

(defconst lsp-elixir--get-root (lsp-make-traverser #'(lambda (dir)
                                                       (directory-files dir nil "mix.lock"))))
(lsp-define-stdio-client lsp-elixir "elixir"
                         lsp-elixir--get-root '("~/.emacs.d/elixir_ls/language_server.sh"))


(add-hook 'lsp-after-initialize-hook (lambda ()
                                       (lsp--set-configuration `(:elixirLS (:dialyzerEnabled :json-false)))))


;; (require 'eglot)
;; (add-to-list 'eglot-server-programs '(elixir-mode . ("/Users/ananthakumaran/work/repos/elixir-ls/target/language_server.sh")))

(flycheck-add-next-checker 'lsp-ui '(warning . elixir-credo))

(provide 'init-elixir)

