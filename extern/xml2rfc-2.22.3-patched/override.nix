# this file allows using the build definitions from nixpkgs but using the source code from this folder

with import ~/nixpkgs { };


xml2rfc.overrideDerivation (drv: {
  name = "xml2rfc-ssb-spec";

  # would prefer moving the override up one folder for future seperation of patches 
  # but 'src = ./xml2rfc-2.22.3-patched' somehow doesn't work
  src = ./.; 

  # need to add these to the default.nix in ~/nixpkgs
  #buildInputs = with python.pkgs; [ intervaltree lxml requests pyflakes pycountry google-i18n-address html5lib];
  #propagatedBuildInputs = with python.pkgs; [ intervaltree lxml requests six pycountry google-i18n-address html5lib];

  # overwriting them here gives me an error:
  #   these derivations will be built:
  #   /nix/store/y6m86dpr84g03cm5jcp5bggrl3x93z3l-xml2rfc-ssb-spec.drv
  # building '/nix/store/y6m86dpr84g03cm5jcp5bggrl3x93z3l-xml2rfc-ssb-spec.drv'...
  # unpacking sources
  # unpacking source archive /nix/store/q2b2hrg4w6859iiml2p7fvcsw9gnm382-xml2rfc-2.22.3-patched
  # source root is xml2rfc-2.22.3-patched
  # setting SOURCE_DATE_EPOCH to timestamp 315619200 of file xml2rfc-2.22.3-patched/xml2rfc/writers/v2v3.py
  # patching sources
  # configuring
  # building
  # usage: nix_run_setup [global_opts] cmd1 [cmd1_opts] [cmd2 [cmd2_opts] ...]
  #    or: nix_run_setup --help [cmd1 cmd2 ...]
  #    or: nix_run_setup --help-commands
  #    or: nix_run_setup cmd --help
  # 
  # error: invalid command 'bdist_wheel'
  # builder for '/nix/store/y6m86dpr84g03cm5jcp5bggrl3x93z3l-xml2rfc-ssb-spec.drv' failed with exit code 1
  # error: build of '/nix/store/y6m86dpr84g03cm5jcp5bggrl3x93z3l-xml2rfc-ssb-spec.drv' failed

  # needs dict2xml which isn't packged in nixpkgs right now
  doCheck = false;
})
