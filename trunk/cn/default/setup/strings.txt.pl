# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
#
# The Initial Developer of the Original Code is Everything Solved.
# Portions created by Everything Solved are Copyright (C) 2007
# Everything Solved. All Rights Reserved.
#
# The Original Code is the Bugzilla Bug Tracking System.
#
# Contributor(s): Max Kanat-Alexander <mkanat@bugzilla.org>

# This file contains a single hash named %strings, which is used by the
# installation code to display strings before Template-Toolkit can safely
# be loaded.
#
# Each string supports a very simple substitution system, where you can
# have variables named like ##this## and they'll be replaced by the string
# variable with that name.
#
# Please keep the strings in alphabetical order by their name.

%strings = (
    any  => '任何',
    blacklisted => '(黑名单)',
    checking_for => '正在检查',
    checking_dbd      => '正在检查可用的 perl DBD 模块...',
    checking_optional => '以下的 Perl 模块是可选的：',
    checking_modules  => '正在检查 perl 模块...',
    header => "* 这是基于 ##perl_ver## 的 Bugzilla ##bz_ver##\n"
            . "* 运行于 ##os_name## ##os_ver##",
    install_all => <<EOT,

To attempt an automatic install of every required and optional module
with one command, do:

  ##perl## install-module.pl --all

EOT
    install_data_too_long => <<EOT,
WARNING: Some of the data in the ##table##.##column## column is longer than
its new length limit of ##max_length## characters. The data that needs to be
fixed is printed below with the value of the ##id_column## column first and
then the value of the ##column## column that needs to be fixed:

EOT
    install_module => 'Installing ##module## version ##version##...',
    module_found => "找到 v##ver##",
    module_not_found => "没有找到",
    module_ok => '确定',
    module_unknown_version => "找到未知版本",
    template_precompile   => "Precompiling templates...",
    template_removing_dir => "Removing existing compiled templates...",
);

1;