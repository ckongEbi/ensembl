# patch_70_71_b.sql
#
# Title: Introduce alt allele types
#
# Description: Column added for classifying alt alleles. Needed in conjunction
#              with new AltAlleleGroup class.

ALTER TABLE alt_allele 
    ADD COLUMN type ENUM('PROJECTED','MANUAL','CODING_POTENTIAL','NONE') NOT NULL DEFAULT 'NONE', 
    ADD INDEX (type,alt_allele_id);

# Patch identifier
INSERT INTO meta (species_id, meta_key, meta_value)
  VALUES (NULL, 'patch', 'patch_70_71_b.sql|alt_allele_type');
