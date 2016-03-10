# 简介 #

> Bugzilla 国际化所产生的乱码主要发生在使用双字节编码的东亚国家和地区的语言文字。

> 乱码主要分为两种情况，页面本地化乱码和数据库输出乱码。本文主要介绍如何避免下一种情况的发生。


# 乱码产生的原因 #

> 由于英语之外的其它语言文字的编码方法有些不同，特别是东亚国家和地区的双字节编码，如中文、朝鲜文、日文等。如果在解码时没有与之对应，则会产生乱码，如：
    1. 文字以GB2312保存，查看时用UTF-8格式查看。
    1. 文字被重复编码，解码时只解了一次。
    1. 文字所需要的特殊字体不存在。
> Bugzilla英语默认使用lantin-1，多语言使用UTF-8。只要汉化时模板文件选择以UTF-8保存，在页面上基本不会因为浏览器自动选择的字符编码与实际不符而造成乱码。
> 此处所提及的乱码，主要是指数据库中的输入部分显示为乱码。这种情况，多数是由于使用Template-Tools处理模块文件中的变量（多数用于数据库中相关字段值）重复编码所致。即模板文件是UTF-8编码，数据库中保存的数据是UTF-8格式，Template-Tools处理时重复编码了一次取自数据库的数据。

# 最初的解决思路 #

> 知道了数据库输出产生乱码的原因，解决此类乱码问题才能继续下去。

> 在Bugzilla\Template.pm文件开头加入`use Encoding 'latin1'`，这个时候数据库输入不乱码了，但页面本身文字由于是按UTF-8保存的，所以此时页面就会出现类似"\x{4E3A}"之类的显示。英文版本的为什么汉字基本上不会乱码呢？因为英文原版模板文件不是以UTF-8格式保存的。看来页面乱码和数据库乱码不好同时搞定，数据库输出乱码要单独处理才行。

> ActivePerl 5.8.8自带的模块Encode中有decode方法，最初是想把Bugzilla中所有可能用到汉字的地方都decode一下（`decode("utf8",$var)`）。但很明显，这种方法工作量大，且不好维护。
> 能不能在查询数据库的地方入手呢？比如说重写`DBI::selectrow_array`之类的函数方法？由于我对Perl也不是很熟悉，这个想法最终没有实现。
> 后来一次无意中，看到一个页面的链接上的文字是乱码的，但是当鼠标放在链接上时，浏览器状态栏显示的链接上带的汉字却没有乱码！仔细分析Bugzilla源代码后发现，链接中所有的变量多用 FILTER url\_quote 过滤，而从数据库中查询得到的值多用 FILTER html 或 FILTER html\_light 过滤。这就说明，在 FILTER url\_quote 或 FILTER html\_light 等地方进行decode去掉多余的一次UTF-8编码就应该没问题了！

# 如何解决乱码问题 #

> 为尽量避免修改多个文件，从而造成的修改管理上的麻烦，此处主要修改Bugzilla\Template.pm文件。
### 加入`use Encode;`这样的引用 ###
> 在Template.pm文件开头加入`use Encode;`这样的引用，以使用"decode\_utf8"方法。

### 修改 FILTERS html 过滤 ###
> 在Template.pm 621行附近，将`return $var;`改为：
```
if (utf8::is_utf8($var)) {
	return $var;
	}
else {
	return decode_utf8($var);
}
```

### 修改 FILTERS none 过滤 ###
> 在Template.pm 677行附近，将`none => sub { return decode_utf8($_[0]); } ,`改为：
```
 none => sub { 
	if (utf8::is_utf8($_[0])) {
		return $_[0]; 
	}
	else {
		return decode_utf8($_[0]);
	}
} ,
```
> 修改 FILTERS none 过滤，是因为汉化后的模板文件中很多地方添加了这个过滤，如评论文字，xml等。以减少修改的地方。

### 修改 FILTERS html\_light 过滤 ###
> 在Template.pm 623行附近，将`html_light => \&Bugzilla::Util::html_light_quote,`行前加个“#”号注释掉，并在此行后添加以下内容：
```
html_light => sub {
	my ($var) = (@_);
	if (!utf8::is_utf8($var)) {
		$var = decode_utf8($var);
	}
	return ($var);
},
```
> 由于Template.pm中，使用 html\_light 过滤的地方还有些多，故没有在模板文件中一一找出，使用 FILTERS none。熟悉Perl的朋友可以参照此方法，直接修改Util.pm中123行附近的相关内容。

好了，以上修改基本就完成了。这个修改在Windows 2003 Server,Active Perl 5.8.8,mysql 5.0.41下测试通过，各组件包情况如下：
```
D:\bugzilla-3.2>perl checksetup.pl
* This is Bugzilla 3.1.2 on perl 5.8.8
* Running on Win2003 Build 3790

Checking perl modules...
Checking for                 CGI (v2.93)   ok: found v3.20
Checking for            TimeDate (v2.21)   ok: found v2.22
Checking for           PathTools (v0.84)   ok: found v3.12
Checking for                 DBI (v1.41)   ok: found v1.52
Checking for    Template-Toolkit (v2.12)   ok: found v2.19
Checking for          Email-Send (v2.16)   ok: found v2.181
Checking for Email-MIME-Modifier (any)     ok: found v1.440

Checking available perl DBD modules...
Checking for              DBD-Pg (v1.45)    not found
Checking for           DBD-mysql (v2.9003) ok: found v3.0002

The following Perl modules are optional:
Checking for                  GD (v1.20)   ok: found v2.16
Checking for               Chart (v1.0)    ok: found v2.3
Checking for         Template-GD (any)     ok: found v1.56
Checking for          GDTextUtil (any)     ok: found v0.86
Checking for             GDGraph (any)     ok: found v1.43
Checking for            XML-Twig (any)     ok: found v3.26
Checking for          MIME-tools (v5.406)  ok: found v5.417
Checking for         libwww-perl (any)     ok: found v2.033
Checking for         PatchReader (v0.9.4)  ok: found v0.9.5
Checking for          PerlMagick (any)     ok: found v6.2.8
Checking for           perl-ldap (any)     ok: found v0.34
Checking for          RadiusPerl (any)      not found
Checking for           SOAP-Lite (any)     ok: found v0.55
Checking for         HTML-Parser (v3.40)   ok: found v3.56
Checking for       HTML-Scrubber (any)     ok: found v0.08
Checking for Email-MIME-Attachment-Stripper (any)     ok: found v1.3
Checking for         Email-Reply (any)     ok: found v1.200
Checking for            mod_perl (v1.999022) ok: found v2.000003
Checking for                 CGI (v3.11)   ok: found v3.20
Checking for          Apache-DBI (v0.96)   ok: found v1.06
```

```
mysql> show variables like 'character%';
+--------------------------+---------------------------------------------------------+
| Variable_name            | Value                                                   |
+--------------------------+---------------------------------------------------------+
| character_set_client     | utf8                                                    |
| character_set_connection | utf8                                                    |
| character_set_database   | utf8                                                    |
| character_set_filesystem | binary                                                  |
| character_set_results    | utf8                                                    |
| character_set_server     | utf8                                                    |
| character_set_system     | utf8                                                    |
| character_sets_dir       | D:\Program Files\MySQL\MySQL Server 5.0\share\charsets\ |
+--------------------------+---------------------------------------------------------+
8 rows in set (0.00 sec)
```
> 从大家反馈的情况来看，这种修改方法并不十分完美，期待官方最终解决此类问题。