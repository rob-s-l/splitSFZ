# splitSFZ

Notice:
This is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or any later version.
This software is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
See the GNU General Public License for more details.
http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
Split up large samples in to sfz exported files.


Split up large samples in to sfz exported files.
Will only read what is necessary for AKSampler to run.

Other definitions are neglected
-known problem  is a region defined for all keys fi the slap of a fretless bass
It may give a problem in the tuning. Ommit by text editing in the sfz file, (probably the last) <region> with no <lovel> and <hivel> and keyrange for all keys

If placed in an xcodeproject, adapt the sample path in the control part of the sfz file for loading

use the extension forAKSampler func loadsfzData() to load the sfz to the sampler (in stead of loadsfz()

