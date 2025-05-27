{

    inputs.tsuki.url = "github:MidAutumnMoon/TaysiTsuki";

    outputs = { self, tsuki }: let

        pkgsBrew =
            tsuki.pkgsBrew.appendOverlays [ self.overlays.default ];

    in {

        overlays.default = prev: final: let
            inherit ( final.tsuki.writers ) writeRubyBin;
        in {
            compile-blocklist =
                writeRubyBin "compile-blocklist" {}
                ( builtins.readFile ./compile.rb );
        };

        packages = pkgsBrew ( pkgs: {
            inherit ( pkgs ) compile-blocklist;
        } );

    };

}
