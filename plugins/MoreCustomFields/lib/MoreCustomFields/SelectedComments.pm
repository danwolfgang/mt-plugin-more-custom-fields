package MoreCustomFields::SelectedComments;

use strict;
use warnings;

use MT 4.2;
use base qw(MT::Plugin);

use MT::Util qw( relative_date format_ts );

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

<a
    onclick="jQuery.fn.mtDialog.open('<mt:Var name="script_uri">?__mode=mcf_list_comments&amp;blog_id=<mt:Var name="blog_id">&amp;blog_ids=<mt:Var name="blog_ids">&amp;edit_field=<mt:Var name="field_id">')"
    class="button">
    Choose comment
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
        <img class="remove"
            alt="Remove selected comment"
            title="Remove selected comment"
            src="<mt:StaticWebPath>images/status_icons/close.gif"
            width="9" height="9" />
    </li>
</mt:Loop>
</ul>
    };
}

sub _field_html_params {
    my ($key, $tmpl_key, $tmpl_param) = @_;
    my $app = MT->instance;

    my $id       = $app->param('id');
    my $blog     = $app->blog;
    my $blog_id  = $blog ? $blog->id : 0;
    my $obj_type = $tmpl_param->{obj_type};

    my $field_name  = $tmpl_param->{field_name};
    my $field_value = $tmpl_param->{field_value};
    my @obj_ids = split(/,\s?/, $field_value);

    my @obj_ids_loop;
    foreach my $obj_id (@obj_ids) {
        # Verify that $obj_id is a number. If no Selected Comments are found,
        # it's possible $obj_id could be just a space character, which throws
        # an error. So, this check ensures we always have a valid ID.
        next unless $obj_id =~ m/\d+/;

        my $obj = $app->model('comment')->load($obj_id)
            or next;

        # Trim the comment text to just the first 100 characters.
        my $text = $obj->text;
        my $len = 100;
        if ( length $text > $len ) {
            $text = substr( $text, 0, $len );
            $text .= '...';
        }

        push @obj_ids_loop, {
            field_basename => $field_name,
            obj_id         => $obj_id,
            obj_title      => $text,
            obj_class      => 'comment',         # For the edit link.
            obj_blog_id    => $obj->blog_id,
        };
    }
    $tmpl_param->{selected_objects_loop} = \@obj_ids_loop;
}

# The SelectedComments tag will let you intelligently output the links you
# selected. Use:
# <mt:SelectedComments basename="selected_comments">
#   <mt:If name="__first__">
#     <ul>
#   </mt:If>
#     <li><mt:CommentBody></li>
#   <mt:If name="__last__">
#     </ul>
#   </mt:If>
# </mt:SelectedComments>
sub tag_selected_comments {
    my ($ctx, $args, $cond) = @_;
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $res     = '';

    # The basename of the custom field you want to grab must be specified.
    # It's used later, to load the field data.
    my $cf_basename = $args->{basename};
    if (!$cf_basename) {
        return $ctx->error( 'The SelectedComments block tag requires the '
            . 'basename argument. The basename should be the Selected '
            . 'Comments Custom Fields field basename.' );
    }

    # Grab the field name with the collected data from above. The basename
    # must be unique so it's a good thing to key off of!
    my $field = CustomFields::Field->load( { basename => $cf_basename, } );
    return $ctx->error('A Selected Comments Custom Field with this basename '
        . 'could not be found.') if !$field;

    my $basename = 'field.'.$field->basename;

    # Use Custom Fields find_stashed_by_type to load the correct object. This
    # will decide if it's an entry, page, category, folder, or author archive,
    # then load the object and return it to us.
    use CustomFields::Template::ContextHandlers;
    my $object = eval {
        CustomFields::Template::ContextHandlers::find_stashed_by_type(
            $ctx, $field->obj_type
        )
    };
    return $ctx->error($@) if $@;

    # Create an array of the comment IDs held in the field.
    # $object->$basename is the lookup that actually grabs the data.
    my @comment_ids = split(/,\s?/, $object->$basename)
      if ($object && $object->$basename);
    my $i = 0;
    my $vars = $ctx->{__stash}{vars} ||= {};
    foreach my $comment_id (@comment_ids) {
        # Verify that $comment_id is a number. If no Selected Comments are
        # found, it's possible $comment_id could be just a space character,
        # which throws an error. So, this check ensures we always have a valid
        # comment ID.
        if ($comment_id =~ m/\d+/) {
            # Assign the meta vars
            local $vars->{__first__} = !$i;
            local $vars->{__last__} = !defined $comment_ids[$i + 1];
            local $vars->{__odd__} = ($i % 2) == 0; # 0-based $i
            local $vars->{__even__} = ($i % 2) == 1;
            local $vars->{__counter__} = $i + 1;
            # Assign the selected comment
            local $ctx->{__stash}{comment} = MT->model('comment')->load({
                id => $comment_id,
            });

            my $out = $builder->build($ctx, $tokens);
            if (!defined $out) {
                # A error--perhaps a tag used out of context. Report it.
                return $ctx->error( $builder->errstr );
            }
            $res .= $out;
            $i++; # Increment for the meta vars.
        }
    }
    return $res;
}

# This creates the popup dialog that shows the listing of Entries/Pages that
# can be selected.
sub list_content {
    my $app = shift;
    my $q   = $app->can('query') ? $app->query : $app->param;

    my $blog_id    = $q->param('blog_id');
    my $blog_ids   = $q->param('blog_ids') || $q->param('blog_id');
    my $edit_field = $q->param('edit_field');
    my $search     = $q->param('search');
    my $type       = 'comment';

    die $app->error('Required object type and edit field values missing!')
        unless $type && $edit_field;

    my $plugin = $app->component('MoreCustomFields');

    my %terms = (
        junk_status => $app->model('comment')->NOT_JUNK(),
        visible     => 1,
    );

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
        sort      => 'created_on',
        direction => 'descend',
    );

    my $tmpl = $plugin->load_tmpl('comment_list.mtml');

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
        },
        code => sub {
            my ($obj, $row) = @_;

            $row->{edit_link} = $app->uri(
                mode => 'view',
                args => {
                    _type   => 'comment',
                    id      => $obj->id,
                    blog_id => $obj->blog_id,
                },
            );

            if (my $ts = $obj->created_on) {
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

            $row->{author_name} = $obj->author;

            my $text = $obj->text;
            my $len = 100;
            if ( length $text > $len ) {
                $text = substr( $text, 0, $len );
                $text .= '...';
            }

            $row->{text} = $text;

            return $row;
        },
        terms => \%terms,
        args  => \%args,
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

    my $tmpl = $plugin->load_tmpl('insert_object.mtml', {
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
