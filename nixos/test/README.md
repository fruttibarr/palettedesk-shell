# Testing the NixOS install in a VM

`vm.nix` is a disposable NixOS machine that imports `../module.nix`. Building it checks that the module
evaluates and that every package and option exists; booting it lets you run `../install-nixos.sh` for real.

With Nix installed (any distro):

    nix build --impure --expr \
      '(import "${builtins.getFlake "nixpkgs"}/nixos" { configuration = ./vm.nix; }).vm'
    ./result/bin/run-palettedesk-test-vm      # log in as tester / tester (ssh: port 2223)
    # in the VM: copy the repo in, then ./nixos/install-nixos.sh --yes, then start-hyprland
