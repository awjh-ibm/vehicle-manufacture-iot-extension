/*
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import { Object, Property } from 'fabric-contract-api';
import { Organization } from './organization';

@Object()
export class Manufacturer extends Organization {
    public static getClass() {
        return Organization.generateClass(Manufacturer.name);
    }
    @Property()
    public originCode: string;

    @Property()
    public manufacturerCode: string;

    constructor(
        id: string, name: string,
        originCode: string, manufacturerCode: string,
    ) {
        super(id, name, Manufacturer.name);

        this.originCode = originCode;
        this.manufacturerCode = manufacturerCode;
    }
}
