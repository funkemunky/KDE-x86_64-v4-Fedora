%global v4_optflags -O3 -flto=auto -ffat-lto-objects -fexceptions -g -grecord-gcc-switches -pipe -Wall -Wno-complain-wrong-lang -Werror=format-security -Wp,-U_FORTIFY_SOURCE,-D_FORTIFY_SOURCE=3 -Wp,-D_GLIBCXX_ASSERTIONS -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -fstack-protector-strong -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -m64 -march=x86-64-v4 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection -mtls-dialect=gnu2 -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer

Name:           custom-macros
Version:        1.0
Release:        1%{?dist}
Summary:        COPR buildroot macros for x86-64-v4 KDE rebuilds

License:        MIT
URL:            https://copr.fedorainfracloud.org/
BuildArch:      noarch

%description
This package injects RPM macros into the buildroot so packages built in this
COPR use Fedora-style optimization flags with x86-64-v4 code generation.

%prep

%build

%install
mkdir -p %{buildroot}%{_rpmmacrodir}
cat > %{buildroot}%{_rpmmacrodir}/macros.custom <<'EOF'
%%optflags %{v4_optflags}
EOF

%files
%{_rpmmacrodir}/macros.custom

%changelog
* Fri Apr 17 2026 Codex <codex@openai.com> - 1.0-1
- Initial x86-64-v4 macro package for COPR KDE rebuilds
