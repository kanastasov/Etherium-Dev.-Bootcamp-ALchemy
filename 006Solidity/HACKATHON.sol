// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Hackathon {
    struct Project {
        string title;
        uint[] ratings;
    }
    
    Project[] projects;

    function findWinner() external view returns(Project memory) {
        Project memory topProject; 
        uint topAverage = 0;
        for(uint i = 0; i < projects.length; i++) {
            uint sum;
            for(uint j = 0; j < projects[i].ratings.length; j++) {
                sum += projects[i].ratings[j];
            }
            uint average = sum / projects[i].ratings.length;
            if(average > topAverage) {
                topAverage = average;
                topProject = projects[i];
            }
        }
        return topProject;
    }

    function newProject(string calldata _title) external {
        // creates a new project with a title and an empty ratings array
        projects.push(Project(_title, new uint[](0)));
    }

    function rate(uint _idx, uint _rating) external {
        // rates a project by its index
        projects[_idx].ratings.push(_rating);
    }
}


const { assert } = require('chai');

describe('Hackathon', () => {
    describe('with a single project', () => {
        let contract;
        const projectName = 'Only';

        beforeEach(async () => {
            const Hackathon = await ethers.getContractFactory("Hackathon");
            contract = await Hackathon.deploy();
            await contract.newProject(projectName);
            await contract.rate(0, 4);
        });

        it('should award the sole participant', async () => {
            const winner = await contract.findWinner.call();
            assert.equal(winner.title, projectName);
        });
    });

    describe('with multiple projects', () => {
        describe('and a single judge', () => {
            let contract;
            const participant1 = 'First';
            const expectedWinner = 'Winning';
            const participant2 = 'Second';

            beforeEach(async () => {
                const Hackathon = await ethers.getContractFactory("Hackathon");
                contract = await Hackathon.deploy();
                await contract.newProject(participant1);
                await contract.newProject(expectedWinner);
                await contract.newProject(participant2);
                await contract.rate(0, 4);
                await contract.rate(1, 5);
                await contract.rate(2, 2);
            });

            it('should award the highest rated', async () => {
                const actualWinner = await contract.findWinner.call();
                assert.equal(actualWinner.title, expectedWinner);
            });
        });
        
        describe('and multiple judges', () => {
            let contract;
            const expectedWinner = 'Winning';
            const participant1 = 'First';
            const participant2 = 'Second';

            beforeEach(async () => {
                const Hackathon = await ethers.getContractFactory("Hackathon");
                contract = await Hackathon.deploy();
                const projects = [
                    [participant1, [2, 2, 2, 2, 2, 2]],
                    [participant2, [0, 4]],
                    [expectedWinner, [2, 3, 4]],
                ]
                await Promise.all(projects.map(async ([title, ratings], idx) => {
                    await contract.newProject(title);
                    await Promise.all(ratings.map(async (r) => await contract.rate(idx, r)));
                }));
            });

            it('should award the highest average', async () => {
                const actualWinner = await contract.findWinner.call();
                assert.equal(actualWinner.title, expectedWinner);
            });
        });
    });
});
