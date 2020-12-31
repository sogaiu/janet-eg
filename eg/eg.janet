(import json)
(import ./vendor/path :as path)

# https://janetdocs.com/export.json
(defn- get-db-path
  []
  (if-let [cand-path (os/getenv "JANET_EG_DB_FILE_PATH")]
    cand-path
    (path/join (os/getenv "HOME") "export.json")))

(defn- jddb
  []
  (def db-path (get-db-path))
  (assert (os/stat db-path)
          "failed to find file with data")
  (try
    (json/decode (slurp db-path))
    ([err]
     (eprint "failed to read db file")
     nil)))

(defn- build-idx
  [db]
  (def eg-tbl @{})
  (each m db
    (def name (m "name"))
    (assert name
            "name field did not exist for entry")
    (if-let [egs (get eg-tbl name)]
      (array/push egs m)
      (put eg-tbl
           name @[m])))
  eg-tbl)

(defn- revive-docstring
  [docstring]
  (let [str (string/slice docstring 1 -2) # drop surrounding double quotes
        un (peg/replace-all "\\n" "\n" str) # unescape
        res (string/trim un)]
    res))

(defn- line-blank?
  [l-str]
  (zero? (length (string/trim l-str))))

(defn- example-lines
  [e-str]
  (let [lines (string/split "\n" e-str)]
    (def scanned-lines @[])
    # prune successive blank lines
    (var prev-line-blank false)
    (def last-index (length lines))
    (each line lines
      (let [blank (line-blank? line)]
        (when (or (not blank)
                  (not prev-line-blank))
          (array/push scanned-lines line))
        (if blank
          (set prev-line-blank true)
          (set prev-line-blank false))))
    # prune leading blank lines
    (var cur-idx 0)
    (def last-idx (dec (length scanned-lines)))
    (var found-non-blank false)
    (while (and (not found-non-blank)
                (<= cur-idx last-idx))
      (when (not (line-blank? (get scanned-lines cur-idx)))
        (set found-non-blank true)
        (break))
      (++ cur-idx))
    (assert found-non-blank
            "all lines seem to be blank")
    (def beg-idx cur-idx)
    # prune trailing blank lines
    (set cur-idx last-idx)
    (set found-non-blank false)
    (while (and (not found-non-blank)
                (<= 0 cur-idx))
      (when (not (line-blank? (get scanned-lines cur-idx)))
        (set found-non-blank true)
        (break))
      (-- cur-idx))
    (assert found-non-blank
            "all lines seem to be blank")
    (def end-idx cur-idx)
    # only keep lines starting with and ending with a non-blank line
    (array/slice scanned-lines beg-idx (inc end-idx))))

(def- index
  (let [db (jddb)]
    (assert db
            "failed to load db")
    (build-idx db)))

(defn- eg*
  [name]
  (def name-str
    (cond
      (symbol? name)
      (string name)
      #
      (string? name)
      name
      #
      (error "name must be a symbol or a string")))
  (def egs (index name-str))
  (unless egs
    (print "Sorry, no examples for: " name-str)
    (break))
  #
  (eachk k egs
    (print "[" (inc k) "]")
    (print)
    (let [ex ((get egs k) "example")]
      (each l (example-lines ex)
        (print l)))
    (print))
  #
  (print "Total examples found: <<" (length egs) ">>")
  (print))

(defmacro eg
  [name]
  ~(,eg* ',name))

(comment

 (eg "dyn")

 (eg "loop")

 (eg "match")

 (eg "setdyn")

 (eg "some")

 )
