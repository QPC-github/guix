;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014, 2015, 2016, 2017, 2019, 2020 Eric Bavier <bavier@posteo.net>
;;; Copyright © 2016, 2017, 2018, 2020 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2018 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2018, 2019 Rutger Helling <rhelling@mykolab.com>
;;; Copyright © 2019 Pkill -9 <pkill9@runbox.com>
;;; Copyright © 2020 Vincent Legoll <vincent.legoll@gmail.com>
;;; Copyright © 2020 Morgan Smith <Morgan.J.Smith@outlook.com>
;;; Copyright © 2020 Maxim Cournoyer <maxim.cournoyer@gmail.com>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages debug)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system cmake)
  #:use-module (gnu packages)
  #:use-module (gnu packages attr)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages c)
  #:use-module (gnu packages code)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages gdb)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages image)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages ninja)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pretty-print)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages serialization)
  #:use-module (gnu packages virtualization)
  #:use-module (gnu packages xdisorg)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1))

(define-public delta
  (package
    (name "delta")
    (version "2006.08.03")
    (source
     (origin
      (method url-fetch)
      (uri (list
            (string-append "mirror://debian/pool/main/d/delta/"
                           "delta_" version ".orig.tar.gz")
            ;; This uri seems to send guix download into an infinite loop
            (string-append "http://delta.tigris.org/files/documents/3103/"
                           "33566/delta-" version ".tar.gz")))
      (sha256
       (base32
        "184wh35pf2ddx97319s6sgkzpz48xxkbwzcjpycv009bm53lh61q"))))
    (build-system gnu-build-system)
    (inputs                             ;Installed programs are perl scripts
     `(("perl" ,perl)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             ;; Makefile contains no install target
             (let* ((out (assoc-ref outputs "out"))
                    (bin (string-append out "/bin"))
                    (doc (string-append out "/share/doc/delta-" ,version)))
               (begin
                 (for-each (lambda (h)
                             (install-file h doc))
                           `("License.txt" ,@(find-files "www" ".*\\.html")))
                 (for-each (lambda (b)
                             (install-file b bin))
                           `("delta" "multidelta" "topformflat"))))
             #t))
         (delete 'configure))))         ; no configure script
    (home-page "http://delta.tigris.org/")
    (synopsis "Heuristical file minimizer")
    (description
     "Delta assists you in minimizing \"interesting\" files subject to a test
of their interestingness.  A common such situation is when attempting to
isolate a small failure-inducing substring of a large input that causes your
program to exhibit a bug.")
    ;; See License.txt, which is a bsd-3 license, despite the project's
    ;; home-page pointing to a bsd-2 license.
    (license license:bsd-3)))

(define-public c-reduce
  (package
    (name "c-reduce")
    (version "2.10.0")
    (source
     (origin
      (method url-fetch)
      (uri (list
            (string-append "http://embed.cs.utah.edu/creduce/"
                           "creduce-" version ".tar.gz")))
      (sha256
       (base32 "0qx0zq8jxzx2as2zf0740g7kvgq163ayn3041di4vwk77490y76v"))))
    (build-system gnu-build-system)
    (native-inputs `(("flex" ,flex)))
    (inputs
     `(("astyle"          ,astyle)
       ("llvm"            ,llvm)
       ("clang"           ,clang)
       ("indent"          ,indent)
       ("perl"            ,perl)
       ("exporter-lite"   ,perl-exporter-lite)
       ("file-which"      ,perl-file-which)
       ("getopt-tabular"  ,perl-getopt-tabular)
       ("regex-common"    ,perl-regexp-common)
       ("term-readkey"    ,perl-term-readkey)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (replace 'check
           (lambda _
             (with-directory-excursion "tests"
               ;; Running all tests can take a looong time, and tests 4 and 5
               ;; require frama-c or kcc.  So run just one for sanity.
               (invoke "./run_tests" "1"))))
         (add-after 'install 'set-load-paths
           (lambda* (#:key inputs outputs #:allow-other-keys)
             ;; Tell creduce where to find the perl modules it needs.
             (let* ((out (assoc-ref outputs "out"))
                    (prog (string-append out "/bin/creduce")))
               (wrap-program
                   prog
                 `("PERL5LIB" ":" prefix
                   ,(map (lambda (p)
                           (string-append (assoc-ref inputs p)
                                          "/lib/perl5/site_perl/"
                                          ,(package-version perl)))
                         '("term-readkey"    "exporter-lite"
                           "file-which"      "getopt-tabular"
                           "regex-common")))))
             #t)))))
    (home-page "https://embed.cs.utah.edu/creduce")
    (synopsis "Reducer for interesting code")
    (description
     "C-Reduce is a tool that takes a large C or C++ program that has a
property of interest (such as triggering a compiler bug) and automatically
produces a much smaller C/C++ program that has the same property.  It is
intended for use by people who discover and report bugs in compilers and other
tools that process C/C++ code.")
    (license license:ncsa)))

(define-public american-fuzzy-lop
  (let ((machine (match (or (%current-target-system)
                            (%current-system))
                   ("x86_64-linux"   "x86_64")
                   ("i686-linux"     "i386")
                   ("aarch64-linux"  "aarch64")
                   ("armhf-linux"    "arm")
                   ("mips64el-linux" "mips64el")
                   ;; Prevent errors when querying this package on unsupported
                   ;; platforms, e.g. when running "guix package --search="
                   (_                "UNSUPPORTED"))))
    (package
      (name "american-fuzzy-lop")
      (version "2.56b")             ;It seems all releases have the 'b' suffix
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/google/AFL")
               (commit (string-append "v" version))))
         (sha256
          (base32 "1q1g59gkm48aa4cg9h70jx4i2gapmypgp5rzs156b2avd95vwkn1"))
         (file-name (git-file-name name version))))
      (build-system gnu-build-system)
      (inputs
       `(("qemu" ,qemu-for-american-fuzzy-lop)))
      (arguments
       `(#:make-flags (list (string-append "PREFIX=" (assoc-ref %outputs "out"))
                            (string-append "DOC_PATH=$(PREFIX)/share/doc/"
                                           ,name "-" ,version)
                            "CC=gcc")
         #:phases (modify-phases %standard-phases
                    (add-after 'unpack 'make-git-checkout-writable
                      (lambda _
                        (for-each make-file-writable (find-files "."))
                        #t))
                    (delete 'configure)
                    ,@(if (string=? (%current-system) (or "x86_64-linux"
                                                          "i686-linux"))
                        '()
                        '((add-before 'build 'set-afl-flag
                            (lambda _ (setenv "AFL_NO_X86" "1") #t))
                          (add-after 'install 'remove-x86-programs
                            (lambda* (#:key outputs #:allow-other-keys)
                              (let* ((out (assoc-ref outputs "out"))
                                     (bin (string-append out "/bin/")))
                                (delete-file (string-append bin "afl-gcc"))
                                (delete-file (string-append bin "afl-g++"))
                                (delete-file (string-append bin "afl-clang"))
                                (delete-file (string-append bin "afl-clang++")))
                              #t))))
                    (add-after
                     ;; TODO: Build and install the afl-llvm tool.
                     'install 'install-qemu
                     (lambda* (#:key inputs outputs #:allow-other-keys)
                       (let ((qemu (assoc-ref inputs "qemu"))
                             (out  (assoc-ref outputs "out")))
                         (symlink (string-append qemu "/bin/qemu-" ,machine)
                                  (string-append out "/bin/afl-qemu-trace"))
                         #t)))
                    (delete 'check)))) ; tests are run during 'install phase
      (home-page "https://lcamtuf.coredump.cx/afl/")
      (synopsis "Security-oriented fuzzer")
      (description
       "American fuzzy lop is a security-oriented fuzzer that employs a novel
type of compile-time instrumentation and genetic algorithms to automatically
discover clean, interesting test cases that trigger new internal states in the
targeted binary.  This substantially improves the functional coverage for the
fuzzed code.  The compact synthesized corpora produced by the tool are also
useful for seeding other, more labor- or resource-intensive testing regimes
down the road.")
      (license license:asl2.0))))

(define-public qemu-for-american-fuzzy-lop
  ;; afl only supports using a single afl-qemu-trace executable, so
  ;; we only build qemu for the native target.
  (let ((machine (match (or (%current-target-system)
                            (%current-system))
                   ("x86_64-linux"   "x86_64")
                   ("i686-linux"     "i386")
                   ("aarch64-linux"  "aarch64")
                   ("armhf-linux"    "arm")
                   ("mips64el-linux" "mips64el")
                   ;; Prevent errors when querying this package on unsupported
                   ;; platforms, e.g. when running "guix package --search="
                   (_                "UNSUPPORTED"))))
  (hidden-package
   (package
    (name "qemu")
    (version "2.10.2")
    (source (origin
             (method url-fetch)
             (uri (string-append "https://download.qemu.org/qemu-"
                                 version ".tar.xz"))
             (sha256
              (base32
               "17w21spvaxaidi2am5lpsln8yjpyp2zi3s3gc6nsxj5arlgamzgw"))
             (patches
              (search-patches "qemu-glibc-2.27.patch"))))
    (build-system gnu-build-system)
    (arguments
     `(;; Running tests in parallel can occasionally lead to failures, like:
       ;; boot_sector_test: assertion failed (signature == SIGNATURE): (0x00000000 == 0x0000dead)
       #:parallel-tests? #f
       #:configure-flags
       (list (string-append "--target-list=" ,machine "-linux-user"))
       #:make-flags '("V=1")
       #:phases
       (modify-phases %standard-phases
         (replace 'configure
           (lambda* (#:key inputs outputs (configure-flags '())
                           #:allow-other-keys)
             ;; The `configure' script doesn't understand some of the
             ;; GNU options.  Thus, add a new phase that's compatible.
             (let ((out (assoc-ref outputs "out")))
               (setenv "SHELL" (which "bash"))

               ;; While we're at it, patch for tests.
               (substitute* "tests/libqtest.c"
                 (("/bin/sh") (which "sh")))

               ;; The binaries need to be linked against -lrt.
               (setenv "LDFLAGS" "-lrt")
               (apply invoke
                      `("./configure"
                        ,(string-append "--cc=" (which "gcc"))
                        ;; Some architectures insist on using HOST_CC
                        ,(string-append "--host-cc=" (which "gcc"))
                        "--disable-debug-info" ; save build space
                        "--enable-virtfs"      ; just to be sure
                        ,(string-append "--prefix=" out)
                        ,(string-append "--sysconfdir=/etc")
                        ,@configure-flags)))))
         (add-after
          'unpack 'apply-afl-patches
          (lambda* (#:key inputs #:allow-other-keys)
            (let* ((afl-src (assoc-ref inputs "afl-source"))
                   (patch-dir "qemu_mode/patches"))
              (copy-recursively (string-append afl-src "/"
                                               patch-dir)
                                patch-dir)
              (install-file
               (string-append patch-dir
                              "/afl-qemu-cpu-inl.h")
               ".")
              (copy-file (string-append afl-src "/config.h")
                         "./afl-config.h")
              (install-file (string-append afl-src "/types.h")
                            ".")
              (substitute* "afl-qemu-cpu-inl.h"
                (("\\.\\./\\.\\./config.h") "afl-config.h"))
              (substitute* (string-append patch-dir
                                          "/cpu-exec.diff")
                (("\\.\\./patches/") ""))

              ;; These were already applied to qemu-minimal-2.10.
              (for-each (lambda (obsolete-patch)
                          (delete-file (string-append
                                        patch-dir "/"
                                        obsolete-patch)))
                        (list "configure.diff"
                              "memfd.diff"))

              (for-each (lambda (patch-file)
                          (invoke "patch" "--force" "-p1"
                                  "--input" patch-file))
                        (find-files patch-dir
                                    "\\.diff$"))
              #t)))
         (add-before 'check 'disable-unusable-tests
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (substitute* "tests/Makefile.include"
               ;; Comment out the test-qga test, which needs /sys and
               ;; fails within the build environment.
               (("check-unit-.* tests/test-qga" all)
                (string-append "# " all)))
             (substitute* "tests/Makefile.include"
               ;; Comment out the test-char test, which needs networking and
               ;; fails within the build environment.
               (("check-unit-.* tests/test-char" all)
                (string-append "# " all)))
             #t)))))
    (native-inputs
     `(("python-2" ,python-2) ; QEMU 2 needs Python 2
       ("glib:bin" ,glib "bin")
       ("perl" ,perl)
       ("flex" ,flex)
       ("bison" ,bison)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("afl-source" ,(package-source american-fuzzy-lop))
       ("alsa-lib" ,alsa-lib)
       ("attr" ,attr)
       ("glib" ,glib)
       ("libaio" ,libaio)
       ("libattr" ,attr)
       ("libcap" ,libcap)
       ("libjpeg" ,libjpeg-turbo)
       ("libpng" ,libpng)
       ("ncurses" ,ncurses)
       ("pixman" ,pixman)
       ("util-linux" ,util-linux)
       ("zlib" ,zlib)))
    (home-page "https://www.qemu.org")
    (synopsis "Machine emulator and virtualizer (without GUI) for american fuzzy lop")
    (description
     "QEMU is a generic machine emulator and virtualizer.  This package
of QEMU is used only by the american fuzzy lop package.

When used as a machine emulator, QEMU can run OSes and programs made for one
machine (e.g. an ARM board) on a different machine---e.g., your own PC.  By
using dynamic translation, it achieves very good performance.

When used as a virtualizer, QEMU achieves near native performances by
executing the guest code directly on the host CPU.  QEMU supports
virtualization when executing under the Xen hypervisor or using
the KVM kernel module in Linux.  When using KVM, QEMU can virtualize x86,
server and embedded PowerPC, and S390 guests.")
    ;; Many files are GPLv2+, but some are GPLv2-only---e.g., `memory.c'.
    (license license:gpl2)
    ;; Several tests fail on MIPS.
    (supported-systems (delete "mips64el-linux" %supported-systems))))))

(define-public stress-make
  (let ((commit "97815bed8060de33952475b3498767c91f59ffd9")
        (revision "2"))                 ;No official source distribution
    (package
      (name "stress-make")
      (version (git-version "1.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/lanl/stress-make")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "0k55cy7x0hlc6rgpascl6ibhcfxaash3p9r9r8kwvbm3zag1rmac"))))
      (build-system gnu-build-system)
      (native-inputs
       `(("autoconf" ,autoconf)
         ("automake" ,automake)
         ("go" ,go)))
      (inputs
       `(("make-source" ,(package-source gnu-make))))
      (arguments
       ;; stress-make's configure script insists on having a tarball and does
       ;; not accept a directory name instead.  To let the gnu-build-system's
       ;; patch-* phases work properly, we unpack the source first, then
       ;; repack before the configure phase.
       (let ((make-dir (string-append "make-" (package-version gnu-make))))
         `(#:configure-flags '("--with-make-tar=./make.tar.xz"
                               "make_cv_sys_gnu_glob=yes")
           #:phases
           (modify-phases %standard-phases
             (add-after 'unpack 'unpack-make
               (lambda* (#:key inputs #:allow-other-keys)
                 (invoke "tar" "xf" (assoc-ref inputs "make-source"))))
             (add-after 'unpack-make 'set-default-shell
               (lambda _
                 ;; Taken mostly directly from (@ (gnu packages base) gnu-make)
                 (substitute* (string-append ,make-dir "/src/job.c")
                   (("default_shell = .*$")
                    (format #f "default_shell = \"~a\";\n"
                            (which "sh"))))))
             (add-before 'configure 'repack-make
               (lambda _
                 (invoke "tar" "cJf" "./make.tar.xz" ,make-dir)))
             (add-before 'build 'setup-go
               ;; The Go cache is required starting in Go 1.12, and it needs
               ;; to be writable.
               (lambda _ (setenv "GOCACHE" "/tmp/go-cache") #t))))))
      (home-page "https://github.com/lanl/stress-make")
      (synopsis "Expose race conditions in Makefiles")
      (description
       "Stress Make is a customized GNU Make that explicitly manages the order
in which concurrent jobs are run to provoke erroneous behavior into becoming
manifest.  It can run jobs in the order in which they're launched, in backwards
order, or in random order.  The thought is that if code builds correctly with
Stress Make, then it is likely that the @code{Makefile} contains no race
conditions.")
      ;; stress-make wrapper is under BSD-3-modifications-must-be-indicated,
      ;; and patched GNU Make is under its own license.
      (license (list (license:non-copyleft "LICENSE.md")
                     license:gpl3+)))))

(define-public zzuf
  (package
    (name "zzuf")
    (version "0.15")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/samhocevar/zzuf/releases/download/v"
             version "/" name "-" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1mpzjaksc2qg2hzqflf39pl06p53qam2dn3hkhkcv6p00d2n4kx3"))))
    (build-system gnu-build-system)
    (home-page "https://github.com/samhocevar/zzuf")
    (synopsis "Transparent application input fuzzer")
    (description "Zzuf is a transparent application input fuzzer.  It works by
intercepting file operations and changing random bits in the program's
input.  Zzuf's behaviour is deterministic, making it easy to reproduce bugs.")
    (license license:wtfpl2)))

(define-public scanmem
  (package
    (name "scanmem")
    (version "0.17")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/scanmem/scanmem")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "17p8sh0rj8yqz36ria5bp48c8523zzw3y9g8sbm2jwq7sc27i7s9"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags '("--enable-gui")
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'hardcode-python
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (substitute* "gui/GameConqueror.py"
               (("/usr/bin/env python")
                (string-append (assoc-ref %build-inputs
                                          "python-wrapper") "/bin/python")))
             #t))
         (add-after 'install 'wrap-gameconqueror
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((out               (assoc-ref outputs "out"))
                   (gi-typelib-path   (getenv "GI_TYPELIB_PATH"))
                   (python-path       (getenv "PYTHONPATH")))
               (wrap-program (string-append out "/share/gameconqueror/GameConqueror.py")
                 `("GI_TYPELIB_PATH"        ":" prefix (,gi-typelib-path))
                 `("PYTHONPATH"             ":" prefix (,python-path))))
             #t)))))
    (native-inputs
     `(("libtool" ,libtool)
       ("python-wrapper" ,python-wrapper)
       ("gobject-introspection" ,gobject-introspection)
       ("gtk+" ,gtk+)
       ("intltool" ,intltool)
       ("automake" ,automake)
       ("autoconf" ,autoconf)))
    (inputs
     `(("readline" ,readline)))
    (propagated-inputs
     `(("python-pygobject" ,python-pygobject)))
    (home-page "https://github.com/scanmem/scanmem")
    (synopsis "Memory scanner")
    (description "Scanmem is a debugging utility designed to isolate the
address of an arbitrary variable in an executing process.  Scanmem simply
needs to be told the pid of the process and the value of the variable at
several different times.  After several scans of the process, scanmem isolates
the position of the variable and allows you to modify its value.")
    ;; The library is covered by LGPLv3 or later; the application is covered
    ;; by GPLv3 or later.
    (license (list license:lgpl3+ license:gpl3+))))

(define-public remake
  (package (inherit gnu-make)
    (name "remake")
    (version "4.3-1.5")
    (source (origin
              (method url-fetch)
              (uri (let ((upstream-version
                          (match (string-split version #\-)
                            ((ver sub) (string-append ver "%2Bdbg-" sub)))))
                     (string-append "mirror://sourceforge/bashdb/"
                                    "remake/" upstream-version "/"
                                    "remake-" upstream-version ".tar.gz")))
              (file-name (string-append "remake-" version ".tar.gz"))
              (sha256
               (base32
                "0xlx2485y0israv2pfghmv74lxcv9i5y65agy69mif76yc4vfvif"))
              (patches (search-patches "remake-impure-dirs.patch"))))
    (inputs
     `(("readline" ,readline)
       ,@(package-inputs gnu-make)))
    (home-page "http://bashdb.sourceforge.net/remake/")
    (description "Remake is an enhanced version of GNU Make that adds improved
error reporting, better tracing, profiling, and a debugger.")
    (license license:gpl3+)))

(define-public rr
  (package
    (name "rr")
    (version "5.3.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/mozilla/rr")
                    (commit version)))
              (sha256
               (base32
                "1x6l1xsdksnhz9v50p4r7hhmr077cq20kaywqy1jzdklvkjqzf64"))
              (file-name (git-file-name name version))))
    (build-system cmake-build-system)
    (arguments
     `(#:configure-flags
       ;; The 'rr_exec_stub' is a static binary, which leads CMake to fail
       ;; with:
       ;;
       ;;   file RPATH_CHANGE could not write new RPATH:
       ;;
       ;; Clear CMAKE_INSTALL_RPATH to avoid that problem.
       (list "-DCMAKE_INSTALL_RPATH="
             ,@(if (and (not (%current-target-system))
                        (member (%current-system)
                                '("x86_64-linux" "aarch64-linux")))
                   ;; The toolchain doesn't support '-m32'.
                   '("-Ddisable32bit=ON")
                   '()))

       ;; XXX: Most tests fail with:
       ;;
       ;;  rr needs /proc/sys/kernel/perf_event_paranoid <= 1, but it is 2.
       ;;
       ;; This setting cannot be changed from the build environment, so skip
       ;; the tests.
       #:tests? #f

       #:phases (modify-phases %standard-phases
                  (add-before 'check 'set-home
                    (lambda _
                      ;; Some tests expect 'HOME' to be set.
                      (setenv "HOME" (getcwd))
                      #t)))))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("ninja" ,ninja)
       ("which" ,which)))
    (inputs
     `(("gdb" ,gdb)
       ("cpanproto" ,capnproto)
       ("python" ,python)
       ("python-pexpect" ,python-pexpect)))
    (home-page "https://rr-project.org/")
    (synopsis "Record and reply debugging framework")
    (description
     "rr is a lightweight tool for recording, replaying and debugging
execution of applications (trees of processes and threads).  Debugging extends
GDB with very efficient reverse-execution, which in combination with standard
GDB/x86 features like hardware data watchpoints, makes debugging much more
fun.")
    (license license:expat)))

(define-public libbacktrace
  ;; There are no releases nor tags.
  (let ((revision "1")
        (commit "5009c113981431ae1843ebd29d6ad24eb32fc1b2"))
    (package
      (name "libbacktrace")
      (version (git-version "1.0" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/ianlancetaylor/libbacktrace")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "0663zjpfpnsyv9h3pbp7cgmg9gz79n68bqpdl97y6i0jsx93v1zg"))))
      (build-system gnu-build-system)
      (arguments
       `(#:make-flags '("CFLAGS=-fPIC")))
      (home-page "https://github.com/ianlancetaylor/libbacktrace")
      (synopsis "C library for producing symbolic backtraces")
      (description "The @code{libbacktrace} library can be linked into a C/C++
program to produce symbolic backtraces.")
      (license license:expat))))

(define-public libleak
  (package
    (name "libleak")
    (version "0.3.5")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/WuBingzheng/libleak")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1p8mb0hcfp8hdv1klv6rrpkn2zlhjxgkxbbjsk8kszxv7ijln87d"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f                      ;no test suite
       #:parallel-build? #f             ;jobserver unavailable
       #:phases (modify-phases %standard-phases
                  (add-after 'unpack 'unbundle-libwuya
                    (lambda _
                      (substitute* "Makefile"
                        ((".*make -C libwuya.*") ""))
                      #t))
                  (add-before 'build 'set-CC
                    (lambda _
                      (setenv "CC" "gcc")
                      #t))
                  (delete 'configure)   ;no configure script
                  (replace 'install
                    (lambda* (#:key outputs #:allow-other-keys)
                      (let* ((out (assoc-ref outputs "out")))
                        (install-file "libleak.so" (string-append out "/lib"))
                        #t))))))
    (inputs `(("libbacktrace" ,libbacktrace)
              ("libwuya" ,libwuya)))
    (home-page "https://github.com/WuBingzheng/libleak")
    (synopsis "Memory leaks detection tool")
    (description "The libleak tool detects memory leaks by hooking memory
functions such as @code{malloc}.  It comes as a shared object to be pre-loaded
via @code{LD_PRELOAD} when launching the application.  It prints the full call
stack at suspicious memory leak points.  Modifying or recompiling the target
program is not required, and the detection can be enabled or disabled while
the target application is running.  The overhead incurred by libleak is
smaller than that of other tools such as Valgrind, and it aims to be easier to
use than similar tools like @command{mtrace}.")
    (license license:gpl2+)))

(define-public mspdebug
  (package
    (name "mspdebug")
    (version "0.25")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/dlbeer/mspdebug")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32 "0prgwb5vx6fd4bj12ss1bbb6axj2kjyriyjxqrzd58s5jyyy8d3c"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f                         ; no test suite
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))              ; no configure script
       #:make-flags
       (list (string-append "CC=" ,(cc-for-target))
             "INSTALL=install"
             (string-append "PREFIX=" %output))))
  (inputs
     `(("libusb-compat" ,libusb-compat)
       ("readline" ,readline)))
    (synopsis "Debugging tool for MSP430 MCUs")
    (description "MspDebug supports FET430UIF, eZ430, RF2500 and Olimex
MSP430-JTAG-TINY programmers, as well as many other compatible
devices.  It can be used as a proxy for gdb or as an independent
debugger with support for programming, disassembly and reverse
engineering.")
    (home-page "https://github.com/dlbeer/mspdebug")
    (license license:gpl2+)))
