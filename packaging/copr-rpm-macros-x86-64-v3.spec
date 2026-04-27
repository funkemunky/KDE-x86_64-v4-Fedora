Name:           copr-rpm-macros-x86-64-v3
Version:        1
Release:        1%{?dist}
Summary:        Copr buildroot macros for x86_64-v3 rebuilds

License:        MIT
BuildArch:      noarch

%description
This package installs a small RPM macro override for Copr buildroots.
It keeps Fedora's standard compiler and linker flag stack intact while
raising the x86_64 ISA baseline from x86-64 to x86-64-v3.

%prep

%build

%install
mkdir -p %{buildroot}%{rpmmacrodir}
cat > %{buildroot}%{rpmmacrodir}/macros.copr-x86-64-v3 <<'EOF'
%__cflags_arch_x86_64_level -v3
EOF

%files
%{rpmmacrodir}/macros.copr-x86-64-v3

%changelog
* Mon Apr 27 2026 OpenAI Codex <codex@openai.com> - 1-1
- Install a Copr buildroot macro override for x86_64-v3
