;; -*- lexical-binding: t; -*-

(TeX-add-style-hook
 "nih"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("article" "$fontsize$" "11pt")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("geometry" "margin=0.5in") ("fontspec" "") ("setspace" "") ("hyperref" "hidelinks") ("microtype" "") ("titlesec" "")))
   (TeX-run-style-hooks
    "latex2e"
    "article"
    "art10"
    "art11"
    "geometry"
    "fontspec"
    "setspace"
    "hyperref"
    "microtype"
    "titlesec"))
 :latex)

