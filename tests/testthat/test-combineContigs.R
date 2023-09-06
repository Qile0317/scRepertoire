# test script for combineContigs.R - testcases are NOT comprehensive!

test_that("combineTCR works", {
	data("contig_list")
	
	trial1 <- combineTCR(
		df = lapply(contig_list[1:3], head),
		samples = c("PY", "PY", "PX"),
		ID = c("P", "T", "P")
	)
	expected1 <- readRDS("testdata/combineContigs/combineTCR_list_expected.rds")
	
	expect_identical(trial1, expected1)
	
	trial2 <- combineTCR(
		head(contig_list[[1]]), samples = "PY", ID = "P"
	)[[1]]
	expected2 <- expected1[[1]]
	
	expect_identical(trial2, expected2)
}) 

# TODO combineTCR (need more edge cases, different args, errors, etc.)
# TODO combineBCR
# TODO lvCompare