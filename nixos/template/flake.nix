{
  description = "NixOS Proxmox template for the homelab (VM 9001 on kyoto)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.template = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };

    # nix build .#vma  ->  result/vzdump-qemu-nixos-template.vma.zst
    packages.x86_64-linux.vma =
      self.nixosConfigurations.template.config.system.build.VMA;
  };
}
