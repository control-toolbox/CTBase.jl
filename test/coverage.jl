pushfirst!(LOAD_PATH, @__DIR__)

using Coverage
using CTBase

CTBase.postprocess_coverage()
