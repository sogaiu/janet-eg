(import ./eg/vendor/path)

(declare-project
  :name "janet-eg"
  :url "https://github.com/sogaiu/janet-eg"
  :repo "git+https://github.com/sogaiu/janet-eg.git"
  :dependencies ["https://github.com/janet-lang/json.git"])

(def proj-root
  (os/cwd))

(def src-root
  (path/join proj-root "eg"))

(declare-source
 :source [src-root])

(phony "netrepl" []
       (os/execute
        ["janet" "-e" (string "(os/cd \"" src-root "\")"
                              "(import spork/netrepl)"
                              "(netrepl/server)")] :p))

# XXX: the following can be used to arrange for the overriding of the
#      "test" phony target -- thanks to rduplain and bakpakin
(put (dyn :rules) "test" nil)
(phony "test" ["build"]
       (when (try
               (os/execute ["jg-verdict" "--version"] :p)
               ([err]
                (eprint "judge-gen is required for testing")
                nil))
         (os/execute ["jg-verdict"
                      "-p" proj-root
                      "-s" src-root] :p)))

(phony "judge" ["build"]
       (os/execute ["jg-verdict"
                    "-p" proj-root
                    "-s" src-root] :p))
