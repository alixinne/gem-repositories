# Repositories

_Repositories_ is a gem implementing a ``repupdate`` command that synchronizes
a set of repositories on Git hosts (GitLab, GitHub, Gitea) to a set of
destination Git hosts (currently, only GitLab and Gitea).

Matching repositories accross hosts is based on lowercased repository names. Any
difference in branch HEADS will trigger an update from the source repository to
the backup repositories.

If a repository is present in multiple source repositories, the one with the
most recent branch head will be chosen as the source for the copy to the backup
hosts.

## Installation

Installation as a Gem is not supported yet because of hardcoded dependencies in
the Gemfile. Instead, clone this repository and run `bundle` to install the
dependencies.

## Usage

Setup the hosts as follows in a file called `hosts.yml`:

```yaml
---
hosts:
  - type: github
    username: **insert username**
    token: **insert private token**
    use_as: source
    exclude:
      - some-repository # don't backup this
  - type: gitlab
    base: https://[gitlab-api-domain]/api/v4
    username: **insert username**
    token: **insert private token**
    use_as: backup
```

Then, run the repupdate command. Note that SSH keys must have been configured
for the automatic update to succeed.

```
$ bundle exec repupdate --hosts hosts.yml [--force]
```

## License

This source code is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
