from os.path import join, dirname
from vunit import VUnit, read_json, encode_json

root = join(dirname(__file__))

vu = VUnit.from_argv()

vu.add_json4vhdl()
vu.add_array_util()
vu.add_verification_components()

# https://vunit.github.io/logging/user_guide.html#log-location-preprocessing
vu.enable_location_preprocessing()
vu.enable_location_preprocessing(additional_subprograms=['read_csv', 'send_csv', 'slfn_wait', 'receive_csv'])

vu.add_library('lib').add_source_files([
    join(root, '..', '..', 'srcs', '*.vhd'),
    join(root, '..', '*.vhd'),
    join(root, '*.vhd')
])

tb_cfg = dict(
  file_in = "../data/I.csv",
  file_out = "../data/O.csv",
  window_width=3,
  band_depth=20,#200
  line_width=256, #145
  zpadding="false"
)

vu.set_generic("json_cfg", encode_json(tb_cfg))
vu.set_generic("verbose", "true")

vu.main()
