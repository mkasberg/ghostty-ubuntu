.PHONY: clean

clean:
	# Clean debian build artifacts for zig.
	cd zig0.15 && dh_clean
	# Clean debuan build artifacts for ghostty.
	cd ghostty && dh_clean
	# Clean up package files from the root directory.
	rm -f *.build *.buildinfo *.changes *.dsc *.tar.xz *.tar.gz *.minisig *.upload
