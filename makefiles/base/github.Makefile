#!make
# GitHub CLI Management

_GH_MERGE_FLAGS = --delete-branch --squash

pr-merge-conflicts-from-develop: ## sync develop into current branch and reveal conflicts
	@$(MAKE) --stop --no-print-directory pr-merge-conflicts branch=develop

pr-merge-conflicts-from-master: ## sync master into current branch and reveal conflicts
	@$(MAKE) --stop --no-print-directory pr-merge-conflicts branch=master

pr-merge-conflicts: check-defined-branch ## sync target branch and reveal conflicts => branch=*branch*
	@gh repo sync --branch ${branch} && \
	git merge --autostash origin/${branch}

pr-new-branch: check-defined-branch_name ## create new branch from develop => branch_name="{branch_name}"
	@gh repo sync --branch develop && \
	git checkout develop && \
	git checkout -b ${branch_name}

pr-approve: ## approve current PR
	@gh pr review --approve

pr-create: check-defined-pr_assignee check-defined-pr_reviewer check-defined-pr_target ## create pull request with gh-cli => [pr_assignee="GH username"] [pr_reviewer="GH username"] [pr_target=*target branch*]
	@gh pr create --assignee ${pr_assignee} --base ${pr_target} --reviewer ${pr_reviewer} --draft

pr-draft: ## mark PR as draft
	@gh pr ready --undo

pr-merge: ## squash merge and delete branch
	@gh pr merge ${_GH_MERGE_FLAGS}

pr-merge-auto: ## enable automerge with squash
	@gh pr merge --auto ${_GH_MERGE_FLAGS}

pr-ready: tests ## mark PR as ready and enable automerge
	@gh pr ready
	@$(MAKE) --stop --no-print-directory pr-merge-auto

pr-review: check-defined-pr_number ## checkout, validate guidelines+tests and review PR => [pr_number={number}]
	@gh pr checkout ${pr_number} && \
	$(MAKE) guidelines-check && \
	$(MAKE) tests && \
	$(MAKE) dev && \
	gh pr review ${pr_number}

_GH_WORKFLOW_RUN = gh workflow run --repo Optiways/padam-av

deploy-staging: check-defined-tag ## trigger staging deployment workflow => [tag=*tag to deploy*]
	@$(value _GH_WORKFLOW_RUN) deploy-staging.yml --field tag=${tag}

deploy-production: check-defined-release ## trigger production deployment workflow => [release=*release name*]
	@$(value _GH_WORKFLOW_RUN) deploy-production.yml --field release=${release}

release-create: check-defined-release_tag ## create a GitHub release (tag must exist on master) => [release_tag=*vX.Y.Z*]
	@gh release create ${release_tag} \
		--repo Optiways/padam-av \
		--generate-notes \
		--title "${release_tag}"
