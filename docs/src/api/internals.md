```@meta
EditURL = nothing
```

# Private API

This page lists **non-exported** (internal) symbols of `CoveragePostprocessing`, `CTBase.Strategies`, `CTBase.DevTools`, `CTBase.Orchestration`, `CTBase.Interpolation`, `CTBase.Options`, `CTBase.Descriptions`, `CTBase.Core`, `CTBase.Exceptions`, `CTBase.Unicode`, `DocumenterReference`, `TestRunner`.


---

## From `CoveragePostprocessing`


### `_clean_stale_cov_files!` [Function]

```@docs
CoveragePostprocessing._clean_stale_cov_files!
```


### `_collect_and_move_cov_files!` [Function]

```@docs
CoveragePostprocessing._collect_and_move_cov_files!
```


### `_count_cov_files` [Function]

```@docs
CoveragePostprocessing._count_cov_files
```


### `_generate_coverage_reports!` [Function]

```@docs
CoveragePostprocessing._generate_coverage_reports!
```


### `_get_pid_suffix` [Function]

```@docs
CoveragePostprocessing._get_pid_suffix
```


### `_reset_coverage_dir` [Function]

```@docs
CoveragePostprocessing._reset_coverage_dir
```



---

## From `CTBase.Strategies`


### `_default_parameter` [Function]

```@docs
CTBase.Strategies._default_parameter
```


### `_describe_metadata` [Function]

```@docs
CTBase.Strategies._describe_metadata
```


### `_describe_multi_param_metadata` [Function]

```@docs
CTBase.Strategies._describe_multi_param_metadata
```


### `_describe_parameter_registry` [Function]

```@docs
CTBase.Strategies._describe_parameter_registry
```


### `_describe_single_metadata` [Function]

```@docs
CTBase.Strategies._describe_single_metadata
```


### `_describe_strategy_registry` [Function]

```@docs
CTBase.Strategies._describe_strategy_registry
```


### `_error_unknown_options_strict` [Function]

```@docs
CTBase.Strategies._error_unknown_options_strict
```


### `_find_strategies_using_parameter` [Function]

```@docs
CTBase.Strategies._find_strategies_using_parameter
```


### `_find_strategy_in_registry` [Function]

```@docs
CTBase.Strategies._find_strategy_in_registry
```


### `_print_labeled_multiline` [Function]

```@docs
CTBase.Strategies._print_labeled_multiline
```


### `_raw_options` [Function]

```@docs
CTBase.Strategies._raw_options
```


### `_resolve_key` [Function]

```@docs
CTBase.Strategies._resolve_key
```


### `_route_to_from_namedtuple` [Function]

```@docs
CTBase.Strategies._route_to_from_namedtuple
```


### `_strategy_base_name` [Function]

```@docs
CTBase.Strategies._strategy_base_name
```


### `_strategy_id_set` [Function]

```@docs
CTBase.Strategies._strategy_id_set
```


### `_strategy_type_name` [Function]

```@docs
CTBase.Strategies._strategy_type_name
```


### `_supertype_chain` [Function]

```@docs
CTBase.Strategies._supertype_chain
```


### `_warn_unknown_options_permissive` [Function]

```@docs
CTBase.Strategies._warn_unknown_options_permissive
```


### `extract_global_parameter_from_method` [Function]

```@docs
CTBase.Strategies.extract_global_parameter_from_method
```


### `is_a_parameter` [Function]

```@docs
CTBase.Strategies.is_a_parameter
```


### `is_parameter_type` [Function]

```@docs
CTBase.Strategies.is_parameter_type
```


### `levenshtein_distance` [Function]

```@docs
CTBase.Strategies.levenshtein_distance
```


### `option` [Function]

```@docs
CTBase.Strategies.option
```


### `parameter_id` [Function]

```@docs
CTBase.Strategies.parameter_id
```


### `validate_parameter_type` [Function]

```@docs
CTBase.Strategies.validate_parameter_type
```



---

## From `CTBase.Orchestration`


### `RoutingContext` [Struct]

```@docs
CTBase.Orchestration.RoutingContext
```


### `_build_routed_result` [Function]

```@docs
CTBase.Orchestration._build_routed_result
```


### `_build_routing_context` [Function]

```@docs
CTBase.Orchestration._build_routing_context
```


### `_check_action_option_shadowing` [Function]

```@docs
CTBase.Orchestration._check_action_option_shadowing
```


### `_collect_suggestions_across_strategies` [Function]

```@docs
CTBase.Orchestration._collect_suggestions_across_strategies
```


### `_error_ambiguous_option` [Function]

```@docs
CTBase.Orchestration._error_ambiguous_option
```


### `_error_unknown_option` [Function]

```@docs
CTBase.Orchestration._error_unknown_option
```


### `_find_option_in_registry` [Function]

```@docs
CTBase.Orchestration._find_option_in_registry
```


### `_initialize_routing_dict` [Function]

```@docs
CTBase.Orchestration._initialize_routing_dict
```


### `_route_auto!` [Function]

```@docs
CTBase.Orchestration._route_auto!
```


### `_route_single_option!` [Function]

```@docs
CTBase.Orchestration._route_single_option!
```


### `_route_with_disambiguation!` [Function]

```@docs
CTBase.Orchestration._route_with_disambiguation!
```


### `_separate_action_and_strategy_options` [Function]

```@docs
CTBase.Orchestration._separate_action_and_strategy_options
```


### `_warn_unknown_option_permissive` [Function]

```@docs
CTBase.Orchestration._warn_unknown_option_permissive
```


### `build_alias_to_primary_map` [Function]

```@docs
CTBase.Orchestration.build_alias_to_primary_map
```



---

## From `CTBase.Interpolation`


### `AbstractInterpolation` [Abstract Type]

```@docs
CTBase.Interpolation.AbstractInterpolation
```


### `Constant` [Struct]

```@docs
CTBase.Interpolation.Constant
```


### `Linear` [Struct]

```@docs
CTBase.Interpolation.Linear
```


### `method` [Function]

```@docs
CTBase.Interpolation.method
```



---

## From `CTBase.Options`


### `NotStored` [Constant]

```@docs
CTBase.Options.NotStored
```


### `NotStoredType` [Struct]

```@docs
CTBase.Options.NotStoredType
```


### `_construct_option_definition` [Function]

```@docs
CTBase.Options._construct_option_definition
```



---

## From `CTBase.Descriptions`


### `_compute_similarity` [Function]

```@docs
CTBase.Descriptions._compute_similarity
```


### `_find_similar_descriptions` [Function]

```@docs
CTBase.Descriptions._find_similar_descriptions
```


### `_format_description_candidates` [Function]

```@docs
CTBase.Descriptions._format_description_candidates
```



---

## From `CTBase.Core`


### `_ACTIVE_PALETTE` [Constant]

```@docs
CTBase.Core._ACTIVE_PALETTE
```


### `__display` [Function]

```@docs
CTBase.Core.__display
```


### `__matrix_dimension_storage` [Function]

```@docs
CTBase.Core.__matrix_dimension_storage
```


### `_apply_ansi` [Function]

```@docs
CTBase.Core._apply_ansi
```


### `_bold` [Function]

```@docs
CTBase.Core._bold
```


### `_dim` [Function]

```@docs
CTBase.Core._dim
```


### `_green` [Function]

```@docs
CTBase.Core._green
```


### `_red` [Function]

```@docs
CTBase.Core._red
```


### `_style` [Function]

```@docs
CTBase.Core._style
```


### `_yellow` [Function]

```@docs
CTBase.Core._yellow
```



---

## From `CTBase.Exceptions`


### `_build_primary_pairs` [Function]

```@docs
CTBase.Exceptions._build_primary_pairs
```


### `_build_secondary_pairs` [Function]

```@docs
CTBase.Exceptions._build_secondary_pairs
```


### `_extract_user_frames` [Function]

```@docs
CTBase.Exceptions._extract_user_frames
```


### `_format_diagnostic` [Function]

```@docs
CTBase.Exceptions._format_diagnostic
```


### `_format_user_friendly_error` [Function]

```@docs
CTBase.Exceptions._format_user_friendly_error
```


### `_print_colored` [Function]

```@docs
CTBase.Exceptions._print_colored
```


### `_print_pipe_field` [Function]

```@docs
CTBase.Exceptions._print_pipe_field
```



---

## From `DocumenterReference`


### `APIBuilder` [Abstract Type]

```@docs
DocumenterReference.APIBuilder
```


### `CONFIG` [Constant]

```@docs
DocumenterReference.CONFIG
```


### `DOCTYPE_NAMES` [Constant]

```@docs
DocumenterReference.DOCTYPE_NAMES
```


### `DOCTYPE_ORDER` [Constant]

```@docs
DocumenterReference.DOCTYPE_ORDER
```


### `DocType` [Struct]

```@docs
DocumenterReference.DocType
```


### `PAGE_CONTENT_ACCUMULATOR` [Constant]

```@docs
DocumenterReference.PAGE_CONTENT_ACCUMULATOR
```


### `_Config` [Struct]

```@docs
DocumenterReference._Config
```


### `_build_api_page` [Function]

```@docs
DocumenterReference._build_api_page
```


### `_build_combined_page_content` [Function]

```@docs
DocumenterReference._build_combined_page_content
```


### `_build_page_path` [Function]

```@docs
DocumenterReference._build_page_path
```


### `_build_page_return_structure` [Function]

```@docs
DocumenterReference._build_page_return_structure
```


### `_build_private_page_content` [Function]

```@docs
DocumenterReference._build_private_page_content
```


### `_build_public_page_content` [Function]

```@docs
DocumenterReference._build_public_page_content
```


### `_classify_symbol` [Function]

```@docs
DocumenterReference._classify_symbol
```


### `_collect_external_module_docstrings` [Function]

```@docs
DocumenterReference._collect_external_module_docstrings
```


### `_collect_methods_from_source_files` [Function]

```@docs
DocumenterReference._collect_methods_from_source_files
```


### `_collect_module_docstrings` [Function]

```@docs
DocumenterReference._collect_module_docstrings
```


### `_collect_private_docstrings` [Function]

```@docs
DocumenterReference._collect_private_docstrings
```


### `_default_basename` [Function]

```@docs
DocumenterReference._default_basename
```


### `_default_title` [Function]

```@docs
DocumenterReference._default_title
```


### `_exported_symbols` [Function]

```@docs
DocumenterReference._exported_symbols
```


### `_finalize_api_pages` [Function]

```@docs
DocumenterReference._finalize_api_pages
```


### `_format_datatype_for_docs` [Function]

```@docs
DocumenterReference._format_datatype_for_docs
```


### `_format_type_for_docs` [Function]

```@docs
DocumenterReference._format_type_for_docs
```


### `_format_type_param` [Function]

```@docs
DocumenterReference._format_type_param
```


### `_get_effective_source_files` [Function]

```@docs
DocumenterReference._get_effective_source_files
```


### `_get_source_file` [Function]

```@docs
DocumenterReference._get_source_file
```


### `_get_source_from_docstring` [Function]

```@docs
DocumenterReference._get_source_from_docstring
```


### `_get_source_from_methods` [Function]

```@docs
DocumenterReference._get_source_from_methods
```


### `_has_documentation` [Function]

```@docs
DocumenterReference._has_documentation
```


### `_iterate_over_symbols` [Function]

```@docs
DocumenterReference._iterate_over_symbols
```


### `_method_signature_string` [Function]

```@docs
DocumenterReference._method_signature_string
```


### `_normalize_paths` [Function]

```@docs
DocumenterReference._normalize_paths
```


### `_parse_primary_modules` [Function]

```@docs
DocumenterReference._parse_primary_modules
```


### `_passes_source_filter` [Function]

```@docs
DocumenterReference._passes_source_filter
```


### `_register_config` [Function]

```@docs
DocumenterReference._register_config
```


### `_to_string` [Function]

```@docs
DocumenterReference._to_string
```


### `reset_config!` [Function]

```@docs
DocumenterReference.reset_config!
```



---

## From `TestRunner`


### `TestRunInfo` [Struct]

```@docs
TestRunner.TestRunInfo
```


### `TestSpec` [Struct]

```@docs
TestRunner.TestSpec
```


### `_PROGRESS_BAR_THRESHOLD` [Constant]

```@docs
TestRunner._PROGRESS_BAR_THRESHOLD
```


### `_bar_width` [Function]

```@docs
TestRunner._bar_width
```


### `_block_char_for_severity` [Function]

```@docs
TestRunner._block_char_for_severity
```


### `_builder_to_string` [Function]

```@docs
TestRunner._builder_to_string
```


### `_collect_test_files_recursive` [Function]

```@docs
TestRunner._collect_test_files_recursive
```


### `_color_for_severity` [Function]

```@docs
TestRunner._color_for_severity
```


### `_default_on_test_done` [Function]

```@docs
TestRunner._default_on_test_done
```


### `_ensure_jl` [Function]

```@docs
TestRunner._ensure_jl
```


### `_find_symbol_test_file_rel` [Function]

```@docs
TestRunner._find_symbol_test_file_rel
```


### `_format_progress_line` [Function]

```@docs
TestRunner._format_progress_line
```


### `_glob_to_regex` [Function]

```@docs
TestRunner._glob_to_regex
```


### `_has_failures_in_results` [Function]

```@docs
TestRunner._has_failures_in_results
```


### `_make_default_on_test_done` [Function]

```@docs
TestRunner._make_default_on_test_done
```


### `_normalize_available_tests` [Function]

```@docs
TestRunner._normalize_available_tests
```


### `_normalize_selections` [Function]

```@docs
TestRunner._normalize_selections
```


### `_parse_test_args` [Function]

```@docs
TestRunner._parse_test_args
```


### `_progress_bar` [Function]

```@docs
TestRunner._progress_bar
```


### `_resolve_test` [Function]

```@docs
TestRunner._resolve_test
```


### `_run_single_test` [Function]

```@docs
TestRunner._run_single_test
```


### `_select_tests` [Function]

```@docs
TestRunner._select_tests
```


### `_severity` [Function]

```@docs
TestRunner._severity
```


### `_strip_test_prefix` [Function]

```@docs
TestRunner._strip_test_prefix
```

