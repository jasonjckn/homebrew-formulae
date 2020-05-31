# coding: utf-8
class PatchUrlResolver
  def self.repo
    (ENV["HOMEBREW_GITHUB_ACTOR"] or "d12frosted") + "/" + "homebrew-emacs-plus"
  end

  def self.branch
    ref = ENV["HOMEBREW_GITHUB_REF"]
    if ref
      ref.sub("refs/heads/", "")
    else
      "master"
    end
  end

  def self.url name
    "https://raw.githubusercontent.com/#{repo}/#{branch}/patches/#{name}.patch"
  end
end

class Emacs < Formula
  desc "GNU Emacs text editor"
  homepage "https://www.gnu.org/software/emacs/"

  #
  # Options
  #

  # Opt-out
  option "without-cocoa",
         "Build a non-Cocoa version of Emacs"

  # Opt-in
  option "with-ctags",
         "Don't remove the ctags executable that Emacs provides"
  option "with-x11", "Experimental: build with x11 support"
  option "with-no-titlebar", "Experimental: build without titlebar"
  option "with-debug",
         "Build with debug symbols and debugger friendly optimizations"

  # Emacs 27.x only
  option "with-jansson",
         "Build with jansson support (--HEAD only)"
  option "with-emacs-27-branch",
         "Build from emacs-27-branch (--HEAD only)"
  option "with-native-comp-branch",
         "Build from native comp branch (--HEAD only)"

  option "with-no-frame-refocus", "Disables frame re-focus (ie. closing one frame does not refocus another one)"

  #
  # URLs
  #
  system "git", "config", "--global", 'url.ssh://git@gitlab.us.bank-dns.com:2222/jbjack1/emacs-mirror.git.insteadOf', "https://github.com/emacs-mirror/emacs.git"

  head do
    if build.with? "emacs-27-branch"
      url "https://github.com/emacs-mirror/emacs.git", :branch => "emacs-27"
    elsif build.with? "native-comp-branch"
      url "https://github.com/emacs-mirror/emacs.git", :branch => "feature/native-comp"
    else
      url "https://github.com/emacs-mirror/emacs.git"
    end
  end

  #
  # Dependencies
  #

  head do
    depends_on "autoconf" => :build
    depends_on "gnu-sed" => :build
    depends_on "texinfo" => :build
  end

  depends_on "pkg-config" => :build

  depends_on "gnutls"
  depends_on "librsvg"
  depends_on "little-cms2"

  depends_on :x11 => :optional
  depends_on "dbus" => :optional
  depends_on "mailutils" => :optional

  depends_on "imagemagick@7" => :recommended
  depends_on "imagemagick@6" => :optional
  depends_on "jansson" => :optional

  if build.with? "x11"
    depends_on "freetype" => :recommended
    depends_on "fontconfig" => :recommended
  end

  #
  # Incompatible options
  #

  if build.with? "emacs-27-branch"
    unless build.head?
      odie "--with-emacs-27-branch is supported only on --HEAD"
    end
  end


  #
  # Patches
  #

  if build.with? "no-titlebar"
    if build.with? "emacs-27-branch"
      patch do
        url (PatchUrlResolver.url "no-titlebar-emacs-27")
        sha256 "fdf8dde63c2e1c4cb0b02354ce7f2102c5f8fd9e623f088860aee8d41d7ad38f"
      end
    elsif build.head?
      patch do
        url (PatchUrlResolver.url "no-titlebar-head")
        sha256 "990af9b0e0031bd8118f53e614e6b310739a34175a1001fbafc45eeaa4488c0a"
      end
    else
      patch do
        url (PatchUrlResolver.url "no-titlebar-release")
        sha256 "2059213cc740a49b131a363d6093913fa29f8f67227fc86a82ffe633bbf1a5f5"
      end
    end
  end

  unless build.head?
    patch do
      url (PatchUrlResolver.url "multicolor-fonts")
      sha256 "7597514585c036c01d848b1b2cc073947518522ba6710640b1c027ff47c99ca7"
    end
  end

  if build.with? "no-frame-refocus"
    patch do
      url (PatchUrlResolver.url "no-frame-refocus-cocoa")
      sha256 "fb5777dc890aa07349f143ae65c2bcf43edad6febfd564b01a2235c5a15fcabd"
    end
  end

  patch do
    url (PatchUrlResolver.url "fix-window-role")
    sha256 "1f8423ea7e6e66c9ac6dd8e37b119972daa1264de00172a24a79a710efcb8130"
  end

  if build.with? "emacs-27-branch"
    patch do
      url (PatchUrlResolver.url "system-appearance-emacs-27")
      sha256 "82252e2858a0eba95148661264e390eaf37349fec9c30881d3c1299bfaee8b21"
    end
  elsif build.head?
    patch do
      url (PatchUrlResolver.url "system-appearance")
      sha256 "2a0ce452b164eee3689ee0c58e1f47db368cb21b724cda56c33f6fe57d95e9b7"
    end
  end


  def install
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --enable-locallisppath=#{HOMEBREW_PREFIX}/share/emacs/site-lisp
      --infodir=#{info}/emacs
      --prefix=#{prefix}
    ]

    args << "--with-xml2"
    args << "--with-gnutls"


    if build.with? "debug"
      ENV.append "CFLAGS", "-g -Og"
    end

    if build.with? "dbus"
      args << "--with-dbus"
    else
      args << "--without-dbus"
    end

    # Note that if ./configure is passed --with-imagemagick but can't find the
    # library it does not fail but imagemagick support will not be available.
    # See: https://debbugs.gnu.org/cgi/bugreport.cgi?bug=24455
    if build.with?("imagemagick@6") || build.with?("imagemagick@7")
      args << "--with-imagemagick"
    else
      args << "--without-imagemagick"
    end

    # Emacs 27.x (current HEAD) supports imagemagick7 but not Emacs 26.x
    if build.with? "imagemagick@7"
      imagemagick_lib_path =  Formula["imagemagick@7"].opt_lib/"pkgconfig"
      unless build.head?
        odie "--with-imagemagick@7 is supported only on --HEAD"
      end
      ohai "ImageMagick PKG_CONFIG_PATH: ", imagemagick_lib_path
      ENV.prepend_path "PKG_CONFIG_PATH", imagemagick_lib_path
    elsif build.with? "imagemagick@6"
      imagemagick_lib_path =  Formula["imagemagick@6"].opt_lib/"pkgconfig"
      ohai "ImageMagick PKG_CONFIG_PATH: ", imagemagick_lib_path
      ENV.prepend_path "PKG_CONFIG_PATH", imagemagick_lib_path
    end

    if build.with? "jansson"
      unless build.head?
        odie "--with-jansson is supported only on --HEAD"
      end
      args << "--with-json"
    end

    args << "--with-modules"
    args << "--with-rsvg"
    args << "--without-pop" if build.with? "mailutils"

    if build.head?
      ENV.prepend_path "PATH", Formula["gnu-sed"].opt_libexec/"gnubin"
      system "./autogen.sh"
    end

    if build.with? "native-comp-branch"
      args << "--with-nativecomp"
      ENV["CC"] = "gcc-9"
      ENV["CPP"] = "cpp-9"
      ENV.prepend_path "PATH", "/usr/local/bin"
      ENV.append "CFLAGS", "-I/usr/local/include"
      ENV.append "CPPFLAGS", "-I/usr/local/include"
      ENV.append "LDFLAGS", "-I/usr/local/include"
      ENV.prepend_path "PKG_CONFIG_PATH", "/usr/local/lib/pkgconfig/"
    end

    if build.with? "cocoa" and build.without? "x11"
      args << "--with-ns" << "--disable-ns-self-contained"

      system "./configure", *args

      # Disable aligned_alloc on Mojave. See issue: https://github.com/daviderestivo/homebrew-emacs-head/issues/15
      if MacOS.version <= :mojave
        ohai "Force disabling of aligned_alloc on macOS <= Mojave"
        configure_h_filtered = File.read("src/config.h")
                                 .gsub("#define HAVE_ALIGNED_ALLOC 1", "#undef HAVE_ALIGNED_ALLOC")
                                 .gsub("#define HAVE_DECL_ALIGNED_ALLOC 1", "#undef HAVE_DECL_ALIGNED_ALLOC")
                                 .gsub("#define HAVE_ALLOCA 1", "#undef HAVE_ALLOCA")
                                 .gsub("#define HAVE_ALLOCA_H 1", "#undef HAVE_ALLOCA_H")
        File.open("src/config.h", "w") do |f|
          f.write(configure_h_filtered)
        end
      end

      system "make"
      system "make", "install"

      prefix.install "nextstep/Emacs.app"

      # Replace the symlink with one that avoids starting Cocoa.
      (bin/"emacs").unlink # Kill the existing symlink
      (bin/"emacs").write <<~EOS
        #!/bin/bash
        exec #{prefix}/Emacs.app/Contents/MacOS/Emacs "$@"
      EOS
    else
      if build.with? "x11"
        # These libs are not specified in xft's .pc. See:
        # https://trac.macports.org/browser/trunk/dports/editors/emacs/Portfile#L74
        # https://github.com/Homebrew/homebrew/issues/8156
        ENV.append "LDFLAGS", "-lfreetype -lfontconfig"
        args << "--with-x"
        args << "--with-gif=no" << "--with-tiff=no" << "--with-jpeg=no"
      else
        args << "--without-x"
      end
      args << "--without-ns"

      system "./configure", *args

      # Disable aligned_alloc on Mojave. See issue: https://github.com/daviderestivo/homebrew-emacs-head/issues/15
      if MacOS.version <= :mojave
        ohai "Force disabling of aligned_alloc on macOS <= Mojave"
        configure_h_filtered = File.read("src/config.h")
                                 .gsub("#define HAVE_ALIGNED_ALLOC 1", "#undef HAVE_ALIGNED_ALLOC")
                                 .gsub("#define HAVE_DECL_ALIGNED_ALLOC 1", "#undef HAVE_DECL_ALIGNED_ALLOC")
                                 .gsub("#define HAVE_ALLOCA 1", "#undef HAVE_ALLOCA")
                                 .gsub("#define HAVE_ALLOCA_H 1", "#undef HAVE_ALLOCA_H")
        File.open("src/config.h", "w") do |f|
          f.write(configure_h_filtered)
        end
      end

      system "make", "bootstrap"
      system "make", "install"
    end

    # Follow MacPorts and don't install ctags from Emacs. This allows Vim
    # and Emacs and ctags to play together without violence.
    if build.without? "ctags"
      (bin/"ctags").unlink
      (man1/"ctags.1.gz").unlink
    end
  end

  plist_options manual: "emacs"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/emacs</string>
          <string>--fg-daemon</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardOutPath</key>
        <string>/tmp/homebrew.mxcl.emacs-plus.stdout.log</string>
        <key>StandardErrorPath</key>
        <string>/tmp/homebrew.mxcl.emacs-plus.stderr.log</string>
      </dict>
      </plist>
    EOS
  end

  def caveats
    <<~EOS
      Emacs.app was installed to:
        #{prefix}

      To link the application to default Homebrew App location:
        ln -s #{prefix}/Emacs.app /Applications

      --natural-title-bar option was removed from this formula, in order to
        duplicate its effect add following line to your init.el file
        (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
        (add-to-list 'default-frame-alist '(ns-appearance . dark))
      or:
        (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
        (add-to-list 'default-frame-alist '(ns-appearance . light))

    EOS
  end

  test do
    assert_equal "4", shell_output("#{bin}/emacs --batch --eval=\"(print (+ 2 2))\"").strip
  end
end
