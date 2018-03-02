#!/usr/bin/env groovy

library("govuk")

REPOSITORY = "gds-sso"

def rubyVersions = [
  "2.2",
  "2.3",
  "2.4",
]

def gemfiles = [
  "rails_4",
  "rails_5",
]

node {

  try {
    stage("Checkout") {
      checkout(scm)
      govuk.mergeMasterBranch()
    }

    stage("Trap signon processes") {
      sh('trap "./stop_signon.sh" EXIT')
    }

    stage("Remove lock files") {
      sh("rm -f Gemfile.lock")
      sh("rm -f gemfiles/*.gemfile.lock")
    }

    stage("Clean up git") {
      sh("git clean -fxde /tmp")
    }

    stage("Start signon") {
      sh("./start_signon.sh")
    }

    for (rubyVersion in rubyVersions) {
      for(gemfile in gemfiles) {
        stage("Test with ruby $rubyVersion and gemfile $gemfile") {
          govuk.setEnvar("RBENV_VERSION", rubyVersion)
          govuk.setEnvar("BUNDLE_GEMFILE", "gemfiles/${gemfile}.gemfile")
          govuk.bundleGem()
          govuk.runTests()
        }
      }
    }
    sh("unset RBENV_VERSION")
    sh("unset BUNDLE_GEMFILE")

    if (env.BRANCH_NAME == "master") {
      stage("Push release tag") {
        echo("Pushing tag")
        govuk.pushTag(REPOSITORY, env.BRANCH_NAME, "release_" + env.BUILD_NUMBER)
      }

      stage("Publish gem") {
        echo("Publishing gem")
        govuk.publishGem(REPOSITORY, env.BRANCH_NAME)
      }
    }

  } catch (e) {
    currentBuild.result = "FAILED"
    step([$class: "Mailer",
          notifyEveryUnstableBuild: true,
          recipients: "govuk-ci-notifications@digital.cabinet-office.gov.uk",
          sendToIndividuals: true])
    throw e
  }
}
