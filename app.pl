#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Util qw(dumper);
use FindBin qw($Bin);
use File::Spec::Functions;

my $config = plugin 'JSONConfig';
app->secrets( [ $config->{'app_secret'} ] );
plugin Minion => { File => $config->{'minion_db'} };
my $repo     = $config->{'repo'};
my $repo_url = $config->{'repo_url'};

unless ( -d $repo ) {
    my $git_clone = `git clone $repo_url`;
}

# Job queue task
app->minion->add_task(
    convert_doc => sub {
        my $job = shift;
        my $doc = shift;
        $job->app->log->info( "Converting $doc" );

        # Get the latest files from the Github repo
        my $git_pull = `cd $repo && git pull`;
        $job->app->log->info( "Git pull results: $git_pull" );

        # Determine which formats need to be output (.md, .docx, .odt)
        my %format_alts = (
            md   => [ 'docx', 'odt' ],
            docx => [ 'odt',  'md' ],
            odt  => [ 'md',   'docx' ]
        );

        # Dictionary for the extentions
        my %formats = (
            md   => 'markdown',
            docx => 'docx',
            odt  => 'odt'
        );

        # Dictionary for the repo directories
        my %format_dirs = (
            md   => 'markdown',
            docx => 'msword',
            odt  => 'openoffice'
        );

        my ( $volume, $directories, $file ) = File::Spec->splitpath( $doc );
        my @dirs = File::Spec->splitdir( $directories );
        #### TODO replace this with something more sensible:
        my ( $ext )       = $file =~ /\.(\w+)$/;
        my ( $file_name ) = $file =~ /(.*)\./;
        if ( $ext eq 'odt' ) {
            $job->app->log->info( "No support for odt yet..." );
            return;
        }
        unless ( $directories =~ /$format_dirs{ $ext }/ ) {
            $job->app->log->info(
                "The file doesn't appear to be in an expected directory..." );
            return;
        }
        ####
        my $alts = $format_alts{$ext};

        # Output the modified file in the alternate formats
        for my $to_create ( @$alts ) {
            $job->app->log->info( "Going to create: $to_create" );

            # Do I have an adequate directory to put this file in?
            my $target_dir = File::Spec->catdir( $repo, $dirs[0], $format_dirs{$to_create} );
            unless ( -d $target_dir ) {
                $job->app->log->info( "No target directory, creating..." );
                mkdir $target_dir;
            }
            my $cmd
                = "pandoc -f $formats{ $ext } -t $to_create $repo/$directories$file -o $target_dir/$file_name.$to_create";
            my $output = `$cmd`;
        }

        # Git commit the changes
        my $git_commit
            = `cd $repo && git add . && git commit -a -m 'Doc bot: updating alternate versions of $file'`;

        # Git push the changes back to the repo
        my $git_push = `cd $repo && git push`;

        # TODO Send a report to someone?
    }
);

post '/github' => sub {
    my $c       = shift;
    my $body    = $c->req->body;
    my $payload = decode_json $body;
    my $commits = $payload->{'commits'};
    my $jobs    = 0;
    for my $commit ( @$commits ) {

        # If this is a doc bot commit, skip it
        if ( $commit->{'message'} =~ /Doc bot:/g ) {
            $c->app->log->debug(
                "Skipping because this is a doc bot commit" );
            next;
        }

        # If files are added or changed, add them to the queue
        if ( $commit->{'modified'} || $commit->{'added'} ) {
            my @changes = @{ $commit->{'modified'} };
            push( @changes, @{ $commit->{'added'} } );
            for my $mod ( @changes ) {
                $jobs++;
                $c->minion->enqueue( 'convert_doc', [$mod] );
            }
            return $c->render(
                json => {
                    jobs    => $jobs,
                    message => "Added $jobs jobs to the queue",
                    version => "Version: $config->{'app_version'}"
                },
                status => 200
            );
        }
    }
    if ( $jobs == 0 ) {
        return $c->render(
            json   => { message => "No new or changed files" },
            status => 422
        );
    }
};

app->start;
