#!/usr/bin/perl

use strict;
use warnings;

use lib qw(lib t/lib);

BEGIN {
    $ENV{MT_CONFIG} = 'mysql-test.cfg';
}

use IPC::Open2;

use Test::Base;
plan tests => 2 * blocks;

use MT;
use MT::Test qw(:db);
my $app = MT->instance;

my $website_id;
my $blog_id;
my $author_id;

filters qw{ count2expect inflate_tmpl };

filters {
    template => [qw( chomp inflate_tmpl )],
    expected => [qw( chomp count2expect )],
};

my $mt = MT->instance;

my $obj;

($obj) = $mt->model('website')->load();
$website_id = $obj->id;

$obj = $mt->model('website')->new;
$obj->set_values({
    name => 'web2',
});
$obj->save or die $obj->errstr;

my ($author_role) = $mt->model('role')->load({ name => 'Author' });

my $author = $mt->model('author')->new;
$author->set_values({
    name => 'dummy',
    nickname => 'Dum Dummy',
    password => '12345',
});
$author->save or die $author->errstr;
$author_id = $author->id;

$obj = $mt->model('blog')->create_default_blog('blog1', undef, $website_id);
$blog_id = $obj->id;
$author->add_role($author_role, $obj);

$obj = $mt->model('blog')->create_default_blog('blog2', undef, $website_id);

my @categories;
$obj = $mt->model('category')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    label => 'cat1',
});
$obj->save or die $obj->errstr;
push @categories, $obj;

$obj = $mt->model('category')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    label => 'cat2',
});
$obj->save or die $obj->errstr;
push @categories, $obj;

$obj = $mt->model('category')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    label => 'subcat1',
    parent => $categories[0]->id,
});
$obj->save or die $obj->errstr;
push @categories, $obj;

$obj = $mt->model('category')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    label => 'subcat2',
    parent => $categories[0]->id,
});
$obj->save or die $obj->errstr;
push @categories, $obj;

$obj = $mt->model('category')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    label => 'subsubcat',
    parent => $categories[2]->id,
});
$obj->save or die $obj->errstr;
push @categories, $obj;

my @assets;
$obj = $mt->model('asset')->new;
$obj->set_values({
    blog_id => $blog_id,
    label => 'asset1',
});
$obj->tags(qw(TEST1 TEST2));
$obj->save or die $obj->errstr;
push @assets, $obj;

$obj = $mt->model('asset')->new;
$obj->set_values({
    blog_id => $blog_id,
    label => 'asset2',
});
$obj->tags(qw(TEST1 TEST2));
$obj->save or die $obj->errstr;
push @assets, $obj;

$obj = $mt->model('entry')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    status => MT::Entry::RELEASE,
});
$obj->tags(qw(TEST1 TEST2));
$obj->save or die $obj->errstr;
$obj->authored_on($obj->authored_on - 60);
$obj->save;

$obj = $mt->model('entry')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    status => MT::Entry::RELEASE,
    pinged_urls => "http://see.you.com/later.html\nhttp://see.you.com/soon.html",
});
$obj->tags(qw(TEST1 TEST2));
$obj->save or die $obj->errstr;

foreach my $ix (0..1) {
    my $plac = $mt->model('placement')->new;
    $plac->set_values({
        blog_id => $blog_id,
        entry_id => $obj->id,
        category_id => $categories[ $ix ]->id,
        is_primary => ($ix == 0 ? 1 : 0),
    });
    $plac->save or die $plac->errstr;

    $plac = $mt->model('placement')->new;
    $plac->set_values({
        blog_id => $blog_id,
        entry_id => $obj->id,
        category_id => $categories[ $ix+2 ]->id,
        is_primary => 0,
    });
    $plac->save or die $plac->errstr;

    my $asset = $assets[$ix];
    my $oas = $mt->model('objectasset')->new;
    $oas->set_values({
        blog_id => $blog_id,
        object_id => $obj->id,
        object_ds => 'entry',
        asset_id => $asset->id,
    });
    $oas->save or die $oas->errstr;
}

my $comment = $mt->model('comment')->new;
$comment->set_values({
    blog_id => $blog_id,
    entry_id => $obj->id,
    commenter_id => $author_id,
    visible => 1,
});
$comment->save or die $obj->errstr;

for my $ix (0..1) {
    my $c2 = $mt->model('comment')->new;
    $c2->set_values({
        blog_id => $blog_id,
        entry_id => $obj->id,
        parent_id => $comment->id,
        commenter_id => $author_id,
        visible => 1,
    });
    $c2->save or die $obj->errstr;
}

my @folders;
$obj = $mt->model('folder')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    label => 'folder1',
});
$obj->save or die $obj->errstr;
push @folders, $obj;

$obj = $mt->model('folder')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    label => 'folder2',
});
$obj->save or die $obj->errstr;
push @folders, $obj;

$obj = $mt->model('folder')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    label => 'subfold1',
    parent => $folders[0]->id,
});
$obj->save or die $obj->errstr;
push @folders, $obj;

$obj = $mt->model('folder')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    label => 'subfold2',
    parent => $folders[0]->id,
});
$obj->save or die $obj->errstr;
push @folders, $obj;

$obj = $mt->model('folder')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    label => 'subsubfold',
    parent => $folders[2]->id,
});
$obj->save or die $obj->errstr;
push @folders, $obj;


$obj = $mt->model('page')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    status => MT::Entry::RELEASE,
});
$obj->tags(qw(TEST1 TEST2));
$obj->save or die $obj->errstr;
$obj->authored_on($obj->authored_on - 60);
$obj->save;

$obj = $mt->model('page')->new;
$obj->set_values({
    blog_id => $blog_id,
    author_id => $author_id,
    status => MT::Entry::RELEASE,
});
$obj->tags(qw(TEST1 TEST2));
$obj->save or die $obj->errstr;

foreach my $ix (0..1) {
    my $fold = $folders[$ix];
    my $plac = $mt->model('placement')->new;
    $plac->set_values({
        blog_id => $blog_id,
        entry_id => $obj->id,
        category_id => $fold->id,
        is_primary => ($ix == 0 ? 1 : 0),
    });
    $plac->save or die $plac->errstr;

    my $asset = $assets[$ix];
    my $oas = $mt->model('objectasset')->new;
    $oas->set_values({
        blog_id => $blog_id,
        object_id => $obj->id,
        object_ds => 'entry',
        asset_id => $asset->id,
    });
    $oas->save or die $oas->errstr;
}

for my $ix (1..2) {
    $obj = $mt->model('tbping')->new;
    $obj->set_values({
        blog_id => $blog_id,
        ip => '1.2.3.'.$ix,
        visible => 1,
        tb_id => 0,
    });
    $obj->save or die $obj->errstr;
}


run {
    my $block = shift;

SKIP:
    {
        skip $block->skip, 1 if $block->skip;

        my $tmpl = $app->model('template')->new;
        $tmpl->text( $block->template );
        my $ctx = $tmpl->context;

        if ($block->name eq 'mt:SearchResults') {
            require MT::Template::Context::Search;
            $mt->{__tag_handlers}->{'searchresults'}->[0] = 
                \&MT::Template::Context::Search::_hdlr_results;

            my @elist = $mt->model('entry')->load({ blog_id => $blog_id });
            $ctx->stash('results', sub { return shift @elist });
            $ctx->stash('count', 2);
        }

        my $blog = MT::Blog->load($blog_id);
        $ctx->stash( 'blog',          $blog );
        $ctx->stash( 'blog_id',       $blog->id );
        $ctx->stash( 'local_blog_id', $blog->id );
        $ctx->stash( 'builder',       MT::Builder->new );

        my $result = $tmpl->build;
        $result =~ s/^(\r\n|\r|\n|\s)+|(\r\n|\r|\n|\s)+\z//g;

        is( $result, $block->expected, $block->name );
    }
};

sub php_test_script {
    my ( $template, $text ) = @_;
    $text ||= '';

    my $test_script = <<PHP;
<?php
\$MT_HOME   = '@{[ $ENV{MT_HOME} ? $ENV{MT_HOME} : '.' ]}';
\$MT_CONFIG = '@{[ $app->find_config ]}';
\$blog_id   = '$blog_id';
\$tmpl = <<<__TMPL__
$template
__TMPL__
;
\$text = <<<__TMPL__
$text
__TMPL__
;
PHP
    $test_script .= <<'PHP';
include_once($MT_HOME . '/php/mt.php');
include_once($MT_HOME . '/php/lib/MTUtil.php');

$mt = MT::get_instance(1, $MT_CONFIG);
$mt->init_plugins();

$db = $mt->db();
$ctx =& $mt->context();

$ctx->stash('blog_id', $blog_id);
$ctx->stash('local_blog_id', $blog_id);
$blog = $db->fetch_blog($blog_id);
$ctx->stash('blog', $blog);

if ($ctx->_compile_source('evaluated template', $tmpl, $_var_compiled)) {
    $ctx->_eval('?>' . $_var_compiled);
} else {
    print('Error compiling template module.');
}

?>
PHP
}

SKIP:
{
    unless ( join( '', `php --version 2>&1` ) =~ m/^php/i ) {
        skip "Can't find executable file: php",
            1 * blocks('expected_dynamic');
    }

    run {
        my $block = shift;

    SKIP:
        {
            skip $block->skip, 1 if $block->skip;

            open2( my $php_in, my $php_out, 'php -q' );
            print $php_out &php_test_script( $block->template, $block->text );
            close $php_out;
            my $php_result = do { local $/; <$php_in> };
            $php_result =~ s/^(\r\n|\r|\n|\s)+|(\r\n|\r|\n|\s)+\z//g;

            my $name = $block->name . ' - dynamic';
            is( $php_result, $block->expected, $name );
        }
    };
}

sub count2expect {
    my $count = shift;
    if ($count =~ m/^\d+$/) {
        my $str = '';
        for (my $ix = 1; $ix <= $count; $ix++) {
            my @line;
            push @line, ($ix == 1 ? '1' : '');      # __first__
            push @line, ($ix == $count ? '1' : ''); # __last__
            push @line, $ix;                        # __counter__
            push @line, ($ix % 2 == 1 ? '1' : '');  # __odd__
            push @line, ($ix % 2 == 0 ? '1' : '');  # __even__
            $str .= '|X' . join('X', @line) . 'X|';
        }
        return $str;
    }
    else {
        return $count;
    }
}

sub inflate_tmpl {
    s/____/|X<mt:var name="__first__">X<mt:var name="__last__">X<mt:var name="__counter__">X<mt:var name="__odd__">X<mt:var name="__even__">X|/;
}

__END__

=== mt:Websites
--- template
<mt:Websites>____</mt:Websites>
--- expected
2

=== mt:Blogs
--- template
<mt:Blogs>____</mt:Blogs>
--- expected
2

=== mt:Entries
--- template
<mt:Entries>____</mt:Entries>
--- expected
2

=== mt:Tags
--- template
<mt:Tags>____</mt:Tags>
--- expected
2

=== mt:Pages
--- template
<mt:Pages>____</mt:Pages>
--- expected
2

=== mt:Assets
--- template
<mt:Assets>____</mt:Assets>
--- expected
2

=== mt:IndexList
--- template
<mt:IndexList>____</mt:IndexList>
--- expected
6

=== mt:Archives
--- template
<mt:Archives>____</mt:Archives>
--- expected
4

=== mt:Authors
--- template
<mt:Authors any_type="1" need_entry="0">____</mt:Authors>
--- expected
2

=== mt:EntryTags
--- template
<mt:Entries lastn="1"><mt:EntryTags>____</mt:EntryTags></mt:Entries>
--- expected
2

=== mt:PageTags
--- template
<mt:Pages lastn="1"><mt:PageTags>____</mt:PageTags></mt:Pages>
--- expected
2

=== mt:Loop
--- template
<MTSetVar name='offices3' value='San Francisco' index='0' ->
<MTSetVar name='offices3' value='San Francisco' index='1' ->
<MTSetVar name='offices3' value='San Francisco' index='2' ->
<MTLoop name='offices3'>____</MTLoop>
--- expected
3

=== mt:For
--- template
<MTFor to="2">____</MTFor>
--- expected
3

=== mt:ArchiveList
--- template
<mt:ArchiveList>____</mt:ArchiveList>
--- expected
2

=== mt:Calendar
--- template
<mt:Calendar>____</mt:Calendar>
--- expected
4
--- SKIP

=== mt:Categories
--- template
<mt:Categories show_empty="1">____</mt:Categories>
--- expected
5

=== mt:TopLevelCategories
--- template
<mt:TopLevelCategories show_empty="1">____</mt:TopLevelCategories>
--- expected
2
--- SKIP

=== mt:SubCategories
--- template
<mt:SubCategories top="1">____</mt:SubCategories>
--- expected
2
--- SKIP

=== mt:ParentCategories
--- template
<mt:Categories show_empty="1"><mt:If tag="mt:CategoryLabel" eq="subsubcat"->
<mt:ParentCategories>____</mt:ParentCategories></mt:If></mt:Categories>
--- expected
3
--- SKIP

=== mt:EntryAssets
--- template
<mt:Entries sort_by="authored_on" lastn="1"><mt:EntryAssets>____</mt:EntryAssets></mt:Entries>
--- expected
2

=== mt:EntryCategories
--- template
<mt:Entries lastn="1"><mt:EntryCategories>____</mt:EntryCategories></mt:Entries>
--- expected
2
--- SKIP

=== mt:AssetTags
--- template
<mt:Assets lastn="1"><mt:AssetTags>____</mt:AssetTags></mt:Assets>
--- expected
2

=== mt:PageAssets
--- template
<mt:Pages lastn="1"><mt:PageAssets>____</mt:PageAssets></mt:Pages>
--- expected
2

=== mt:Folders
--- template
<mt:Folders show_empty="1">____</mt:Folders>
--- expected
5

=== mt:TopLevelFolders
--- template
<mt:TopLevelFolders show_empty="1">____</mt:TopLevelFolders>
--- expected
2
--- SKIP

=== mt:ParentFolders
--- template
<mt:Folders show_empty="1"><mt:If tag="mt:FolderLabel" eq="subsubfold"->
<mt:ParentFolders>____</mt:ParentFolders></mt:If></mt:Folders>
--- expected
3
--- SKIP

=== mt:SubFolders
--- template
<mt:SubFolders top="1">____</mt:SubFolders>
--- expected
2
--- SKIP

=== mt:Comments
--- template
<mt:Comments>____</mt:Comments>
--- expected
3

=== mt:CommentReplies
--- template
<mt:Comments><mt:IfCommentReplies><mt:CommentReplies>____</mt:CommentReplies></mt:IfCommentReplies></mt:Comments>
--- expected
2

=== mt:PingsSent
--- template
<mt:Entries lastn="1"><mt:PingsSent>____</mt:PingsSent></mt:Entries>
--- expected
2

=== mt:Pings
--- template
<mt:Pings>____</mt:Pings>
--- expected
2

=== mt:EntryAdditionalCategories
--- template
<mt:Entries lastn="1"><mt:EntryAdditionalCategories>____</mt:EntryAdditionalCategories></mt:Entries>
--- expected
3
--- SKIP

=== mt:EntriesWithSubCategories
--- template
<mt:EntriesWithSubCategories>____</mt:EntriesWithSubCategories>
--- expected
2

=== mt:SearchResults
--- template
<mt:IfStatic><mt:SearchResults>____</mt:SearchResults></mt:IfStatic><mt:IfDynamic>|X1XX1X1XX||XX1X2XX1X|</mt:IfDynamic>
--- expected
2