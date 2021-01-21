module.exports = {
    extends: ['@commitlint/config-conventional'],
    rules : {
        "type-enum" : [
            2,
            "always",
            [
                'feature',
                'bugfix',
                'enh',
                'docs',
                'style',
                'refactor',
                'test',
                'chore',
                'task',
                'revert',
            ]
        ],
        "subject-case" : [
            2,
            "always",
            "sentence-case"
        ],
        "scope-min-length" : [
            2,
            "always",
            2 // Always at least '#' + a number
        ]
    }
}
