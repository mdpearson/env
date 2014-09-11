#!/usr/bin/python
#
# Code derives from demo code in the BBEdit User Manual 10.5.5, available
# at http://pine.barebones.com/manual/BBEdit_10_User_Manual.pdf (p. 308),
# contents of which are Copyright (c) 1992-2013 Bare Bones Software, Inc.
#
# $Id$
# (re)builds a BBEdit-compatible set of ctags within the specified directory
#

import os
import shutil
import subprocess
import sys
import tempfile
import time

FIELD_FLAGS = "--fields=+a+k+m+n+S"
KIND_FLAGS = " ".join(["--C#-kinds=+cEigmnst-efl", "--Java-kinds=+cei-flmp", "--Python-kinds=+cfm"])

if len(sys.argv) != 2:
	script_name = os.path.basename(sys.argv[0]) if len(sys.argv) != 0 else "ctags.py"
	print >> sys.stderr, "usage: %s <path_to_repository>" % script_name
	sys.exit(1)

proj_path = sys.argv[1]

if not os.access(proj_path, os.F_OK):
	print >> sys.stderr, "error: can't access requested directory %s" % proj_path

ctags_bin = "/Applications/BBEdit.app/Contents/Helpers/ctags"
ctags_arg = "--extra=+f-q --excmd=number --file-scope=yes --tag-relative=no %s %s -R" % (FIELD_FLAGS, KIND_FLAGS)
ctags_tmp = tempfile.NamedTemporaryFile(prefix="ctags")
ctags_cmd = "'%s' %s -f '%s' '%s'" % (ctags_bin, ctags_arg, ctags_tmp.name, proj_path)
ctags_err = tempfile.NamedTemporaryFile(prefix="ctags.stderr")

try:
	print >> sys.stderr, "tagging %s ..." % os.path.abspath(proj_path),
	start_time = time.time()
	ret = subprocess.call(ctags_cmd, shell=True, stderr=ctags_err)
	end_time = time.time()
	print >> sys.stderr, "(%.1f sec elapsed)" % (end_time - start_time),

	null_tag_cnt = 0
	with open(ctags_err.name, "r") as fd:
		for err_msg in fd:
			if err_msg.find("ignoring null tag") != -1:
				null_tag_cnt += 1
			else:
				print >> sys.stderr, err_msg

	if ret < 0:
		print >> sys.stderr, "error: ctags terminated with signal %s" % (-ret)
		sys.exit(ret)
	elif ret > 0:
		print >> sys.stderr, "error: ctags returned exit code %s" % ret
		sys.exit(ret)
except OSError as e:
	print >> sys.stderr, "error: exception raised while running ctags: %s" % e.args
	sys.exit(1)

stats = os.stat(ctags_tmp.name)
if stats.st_size == 0:
	print >> sys.stderr, "error: ctags failed to generate a tags file"
	sys.exit(1)
else:
	print >> sys.stderr, "(%.1f Kbytes built)" % (stats.st_size / 1024.0)

ctags_dst = os.path.join(proj_path, "tags")
shutil.copyfile(ctags_tmp.name, ctags_dst)
