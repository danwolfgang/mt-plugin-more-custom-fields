# This is a common module for the Selected Entries and Selected Pages Custom
# Fields. Since they are all so similar they can all make use of some of the
# same code.
package MoreCustomFields::SelectedObject;

use strict;
use warnings;

use MT::Util qw( relative_date format_ts );

# Create the options field displayed on the New/Edit Custom Field screen,
# where the field is defined. The $type variable contains either "entries" or
# "pages" to customize the text for the correct field type.
sub options_field {
    my ($arg_ref) = @_;
    my $type      = $arg_ref->{type};

    return qq{
<div class="textarea-wrapper">
    <input name="options" id="options" class="full-width" value="<mt:Var name="options" escape="html">" />
</div>
<p class="hint">Enter the ID(s) of the blog(s) whose $type should be available for selection. Leave this field blank to use the current blog only.</p>
<p class="hint">Blog IDs should be comma-separated (as in &rdquo;1,12,19,37,112&ldquo;), or the &rdquo;all&ldquo; value may be specified to include all blogs&rsquo; $type.</p>
    };
}

# Populate the field with any saved Entries or Pages.
sub _field_html_params {
    my ($key, $tmpl_key, $tmpl_param) = @_;
    my $app = MT->instance;

    $tmpl_param->{cf_name} = $key eq 'selected_pages' ? 'page'
        : $key eq 'selected_entries' ? 'entry'
        : $key eq 'selected_content' ? 'entry or page'
        : 'entry'; # Entry is just a fallback.
    $tmpl_param->{mode} = $key eq 'selected_pages' ? 'mcf_list_pages'
        : $key eq 'selected_entries' ? 'mcf_list_entries'
        : $key eq 'selected_content' ? 'mcf_list_content'
        : 'mcf_list_entries'; # Entry is just a fallback.

    my $id       = $app->param('id');
    my $blog     = $app->blog;
    my $blog_id  = $blog ? $blog->id : 0;
    my $obj_type = $tmpl_param->{obj_type};

    my $field_name  = $tmpl_param->{field_name};
    my $field_value = $tmpl_param->{field_value};

    # If there is no field value, there is nothing to parse. Likely on the
    # Edit Field screen.
    return unless $field_value;

    my @obj_ids = split(/,\s?/, $field_value);

    my @obj_ids_loop;
    foreach my $obj_id (@obj_ids) {
        # Verify that $obj_id is a number. If no Selected Entries are found, 
        # it's possible $obj_id could be just a space character, which throws
        # an error. So, this check ensures we always have a valid entry ID.
        next unless $obj_id =~ m/\d+/;

        my $obj = MT->model('entry')->load($obj_id)
            or next;

        push @obj_ids_loop, {
            field_basename => $field_name,
            obj_id         => $obj_id,
            obj_title      => $obj->title,
            obj_class      => $obj->class,
            obj_blog_id    => $obj->blog_id,
            obj_permalink  => $obj->permalink,
        };
    }
    $tmpl_param->{selected_objects_loop} = \@obj_ids_loop;
}

# The field HTML.
sub _field_html {
    return q{
<input name="<mt:Var name="field_name">"
    id="<mt:Var name="field_id">"
    class="full-width selected-objects hidden"
    type="hidden"
    value="<mt:Var name="field_value">" />
<input name="<mt:Var name="field_name">_cb_beacon"
    id="<mt:Var name="field_id">"
    class="hidden"
    type="hidden"
    value="1" />

<mt:SetVarBlock name="blog_ids"><mt:If name="options"><mt:Var name="options"><mt:Else><mt:Var name="blog_id"></mt:If></mt:SetVarBlock>

<a
<mt:If tag="Version" lt="5">
    onclick="return openDialog(this.form, '<mt:Var name="mode">', 'blog_id=<mt:Var name="blog_id">&blog_ids=<mt:Var name="blog_ids">&edit_field=<mt:Var name="field_id">')"
<mt:Else>
    onclick="jQuery.fn.mtDialog.open('<mt:Var name="script_uri">?__mode=<mt:Var name="mode">&amp;blog_id=<mt:Var name="blog_id">&amp;blog_ids=<mt:Var name="blog_ids">&amp;edit_field=<mt:Var name="field_id">')"
</mt:If>
    class="<mt:If tag="Version" lt="5">mt4-choose </mt:If>button">
    Choose <mt:Var name="cf_name">
</a>

<ul class="custom-field-selected-objects mcf-listing"
    id="custom-field-selected-objects_<mt:Var name="field_name">">
<mt:Loop name="selected_objects_loop">
    <li id="obj-<mt:Var name="obj_id">" class="sortable">
        <span class="obj-title"><mt:Var name="obj_title"></span>
        <a href="<mt:Var name="script_uri">?__mode=view&amp;_type=<mt:Var name="obj_class">&amp;id=<mt:Var name="obj_id">&amp;blog_id=<mt:Var name="obj_blog_id">"
            class="edit"
            target="_blank"
            title="Edit in a new window."><img
                src="<mt:StaticWebPath>images/status_icons/draft.gif"
                width="9" height="9" alt="Edit" /></a>
        <a href="<mt:Var name="obj_permalink">"
            class="view"
            target="_blank"
            title="View in a new window."><img
                src="<mt:StaticWebPath>images/status_icons/view.gif"
                width="13" height="9" alt="View" /></a>
        <img class="remove"
            alt="Remove selected <mt:Var name="cf_name">"
            title="Remove selected <mt:Var name="cf_name">"
            src="<mt:StaticWebPath>images/status_icons/close.gif"
            width="9" height="9" />
    </li>
</mt:Loop>
</ul>
    };
}

# This creates the popup dialog that shows the listing of Entries/Pages that
# can be selected.
sub list_objects {
    my ($arg_ref)  = @_;
    my $app        = $arg_ref->{app};
    my $blog_ids   = $arg_ref->{blog_ids};
    my $blog_id    = $arg_ref->{blog_id};
    my $type       = $arg_ref->{type};
    my $edit_field = $arg_ref->{edit_field};
    my $search     = $arg_ref->{search} || '';

    die $app->error('Required object type and edit field values missing!')
        unless $type && $edit_field;

    my $plugin = MT->component('MoreCustomFields');

    my %terms = (
         status => MT::Entry->RELEASE(), # Published
    );

    # If this is coming from a Selected Entry or Page CF, then we need to make
    # the popup dialog show both entries and pages as valid options.
    my $entry_or_page;
    if ($app->mode eq 'mcf_list_content') {
        $terms{class} = '*';
        $type = 'entry';
        $entry_or_page = 1;
    }

    my @blog_ids;
    if ($blog_ids eq 'all') {
        # Load all blog IDs.
        my $iter = MT->model('blog')->load_iter();
        while ( my $blog = $iter->() ) {
            push @blog_ids, $blog->id;
        }
    }
    else {
        # Turn this into an array so that all specified blogs can be loaded.
        @blog_ids = split(/,/, $blog_ids);
    }
    $terms{blog_id} = \@blog_ids;

    my %args = (
        sort      => 'authored_on',
        direction => 'descend',
        limit     => 10,
    );

    my $tmpl = $plugin->load_tmpl('entry_list.mtml');

    # For some reason the 'page' _type doesn't get set/picked up for
    # searches, so just set it here.
    $app->param('_type', $type);

    return $app->listing({
        type     => $type,
        template => $tmpl,
        params   => {
            panel_searchable => 1,
            edit_field       => $edit_field,
            search           => $search,
            blog_id          => $blog_id,
            type             => $type,
            entry_or_page    => $entry_or_page,
        },
        code => sub {
            my ($obj, $row) = @_;
            $row->{'status_' . lc MT::Entry::status_text($obj->status)} = 1;

            $row->{entry_permalink} = $obj->permalink
                if $obj->status == MT::Entry->RELEASE();

            if (my $ts = $obj->authored_on) {
                my $date_format = MT::App::CMS->LISTING_DATE_FORMAT();
                my $datetime_format = MT::App::CMS->LISTING_DATETIME_FORMAT();
                $row->{created_on_formatted} = format_ts(
                    $date_format, $ts, $obj->blog,
                    $app->user ? $app->user->preferred_language : undef);
                $row->{created_on_time_formatted} = format_ts(
                    $datetime_format, $ts, $obj->blog,
                    $app->user ? $app->user->preferred_language : undef);
                $row->{created_on_relative} = relative_date(
                    $ts, time, $obj->blog);
            }

            my $author = MT->model('author')->load( $obj->author_id );
            $row->{author_name} = $author ? $author->nickname : '';

            return $row;
        },
        terms => \%terms,
        args  => \%args,
        limit => 10,
    });
}

# When an Entry or Page has been chosen from the listing popup, insert it into
# the Edit Entry/Edit Page screen.
sub select_object {
    my $app    = shift;
    my $plugin = MT->component('MoreCustomFields');

    my $obj_id = $app->param('id')
        or die $app->errtrans('Object ID not specified.');
    
    my $type = $app->param('_type')
        or die $app->errtrans('Object type not specified.');

    my $obj = MT->model($type)->load($obj_id)
        or die $app->errtrans('No [_1] #[_2].', $type, $obj_id);

    my $edit_field = $app->param('edit_field')
        or die $app->errtrans('No edit_field');

    my $tmpl = $plugin->load_tmpl('select_entry.mtml', {
        obj_id        => $obj->id,
        obj_title     => $obj->title,
        obj_blog_id   => $obj->blog_id,
        obj_class     => $obj->class,
        obj_permalink => $obj->permalink,
        edit_field    => $edit_field,
    });

    return $tmpl;
}

1;

__END__
