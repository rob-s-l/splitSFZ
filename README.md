# splitSFZ

Split up large samples in to sfz exported files.
Will only read what is necessary for AKSampler to run.

Other definitions are neglected
-known problem  is a region defined for all keys fi the slap of a fretless bass
It may give a problem in the tuning. Ommit by text editing in the sfz file, (probably the last) <region> with no <lovel> and <hivel> and keyrange for all keys

If placed in an xcodeproject, adapt the sample path in the control part of the sfz file
