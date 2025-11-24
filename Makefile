.PHONY: clean

clean:
	# Clean debian build artifacts for zig.
	cd zig && dh_clean

	# Clean up package files from the root directory.
	rm *.build *.buildinfo *.changes *.dsc *.tar.xz *.upload
