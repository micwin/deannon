# Prevent Double Replacements

Once a region of text has been anonymized, subsequent hints should not reprocess it (e.g., avoid converting `NSX001` again). Investigate tracking replaced spans or tagging tokens to skip future passes.
